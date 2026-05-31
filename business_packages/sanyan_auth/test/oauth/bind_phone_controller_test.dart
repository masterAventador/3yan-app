import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/src/oauth/oauth_gateway.dart';
import 'package:sanyan_auth/src/auth/login_success_handler.dart';
import 'package:sanyan_auth/src/oauth/bind_phone_controller.dart';

class _FakeGateway implements OauthGateway {
  ApiResponse<OauthLoginData> bindResp;
  int bindCalls = 0;
  _FakeGateway({required this.bindResp});
  @override
  Future<ApiResponse<String?>> challenge() async => throw UnimplementedError();
  @override
  Future<ApiResponse<OauthLoginData>> login({required String provider, required String credential, String? nonce}) async => throw UnimplementedError();
  @override
  Future<ApiResponse<OauthLoginData>> bindPhone({required String bindTicket, required String phone, required String code, String? password}) async {
    bindCalls++;
    return bindResp;
  }
}

class _SpyHandler implements LoginSuccessHandler {
  int calls = 0;
  @override
  void handle({required String token, required int userId, bool registerPush = true}) => calls++;
}

class _TestController extends BindPhoneController {
  _TestController({required super.bindTicket, required super.gateway, required super.successHandler});
  List<String> errs = [];
  List<String> infos = [];
  int smsSends = 0;
  bool smsApiOk = true;
  @override
  void showError(String m) => errs.add(m);
  @override
  void showInfo(String m) => infos.add(m);
  @override
  Future<bool> sendSmsApi(String phone) async {
    smsSends++;
    return smsApiOk;
  }
}

void main() {
  _TestController make(ApiResponse<OauthLoginData> resp, {_SpyHandler? h}) {
    final c = _TestController(
      bindTicket: 'bt',
      gateway: _FakeGateway(bindResp: resp),
      successHandler: h ?? _SpyHandler(),
    );
    addTearDown(c.onClose);
    return c;
  }

  test('submit success → handler.handle', () async {
    final h = _SpyHandler();
    final c = make(ApiResponse(success: true, data: const OauthLoginData(token: 'jwt', userId: 5)), h: h);
    c.phone.value = '13800000000';
    c.code.value = '1234';
    await c.submit();
    expect(h.calls, 1);
  });
  test('submit needMergeAuth → info prompt, no handler', () async {
    final h = _SpyHandler();
    final c = make(ApiResponse(success: true, data: const OauthLoginData(needMergeAuth: true)), h: h);
    c.phone.value = '13800000000';
    c.code.value = '1234';
    await c.submit();
    expect(h.calls, 0);
    expect(c.infos, isNotEmpty);
  });
  test('submit failure (ticket used) → error', () async {
    final c = make(ApiResponse(success: false, code: 1013, message: '绑定会话已使用'));
    c.phone.value = '13800000000';
    c.code.value = '1234';
    await c.submit();
    expect(c.errs, isNotEmpty);
  });
  test('submit blocked when phone invalid', () async {
    final c = make(ApiResponse(success: true, data: const OauthLoginData(token: 't', userId: 1)));
    c.phone.value = '123';
    c.code.value = '1234';
    await c.submit();
    expect(c.errs, isNotEmpty);
  });
  test('submit blocked when code empty', () async {
    final c = make(ApiResponse(success: true, data: const OauthLoginData(token: 't', userId: 1)));
    c.phone.value = '13800000000';
    c.code.value = '';
    await c.submit();
    expect(c.errs, isNotEmpty);
  });
  test('sendSms starts 60s countdown', () async {
    final c = make(ApiResponse(success: true, data: const OauthLoginData(token: 't', userId: 1)));
    c.phone.value = '13800000000';
    await c.sendSms();
    expect(c.countdown.value, 60);
    expect(c.smsSends, 1);
  });
  test('sendSms blocked when phone invalid', () async {
    final c = make(ApiResponse(success: true, data: const OauthLoginData(token: 't', userId: 1)));
    c.phone.value = 'bad';
    await c.sendSms();
    expect(c.countdown.value, 0);
    expect(c.smsSends, 0);
  });
}
