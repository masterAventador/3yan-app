import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/src/oauth/sdk_auth_result.dart';
import 'package:sanyan_auth/src/oauth/apple_auth_provider.dart';
import 'package:sanyan_auth/src/oauth/wechat_auth_provider.dart';
import 'package:sanyan_auth/src/oauth/oauth_gateway.dart';
import 'package:sanyan_auth/src/oauth/oauth_provider.dart';
import 'package:sanyan_auth/src/auth/login_success_handler.dart';
import 'package:sanyan_auth/src/oauth/oauth_login_controller.dart';

class _FakeApple implements AppleAuthProvider {
  final SdkAuthResult result;
  _FakeApple(this.result);
  @override
  Future<SdkAuthResult> obtainCredential(String n) async => result;
}

class _FakeWechat implements WechatAuthProvider {
  final SdkAuthResult result;
  final bool neverComplete;
  _FakeWechat(this.result, {this.neverComplete = false});
  @override
  Future<SdkAuthResult> obtainCredential(String n) {
    if (neverComplete) return Completer<SdkAuthResult>().future; // 永不完成
    return Future.value(result);
  }
}

class _FakeGateway implements OauthGateway {
  ApiResponse<String?> challengeResp;
  ApiResponse<OauthLoginData> loginResp;
  _FakeGateway({required this.challengeResp, required this.loginResp});
  @override
  Future<ApiResponse<String?>> challenge() async => challengeResp;
  String? capturedProvider;
  String? capturedNonce;
  @override
  Future<ApiResponse<OauthLoginData>> login(
      {required String provider,
      required String credential,
      String? nonce}) async {
    capturedProvider = provider;
    capturedNonce = nonce;
    return loginResp;
  }
  @override
  Future<ApiResponse<OauthLoginData>> bindPhone(
          {required String bindTicket,
          required String phone,
          required String code,
          String? password}) async =>
      throw UnimplementedError();
}

class _SpyHandler implements LoginSuccessHandler {
  int calls = 0;
  String? token;
  int? userId;
  @override
  void handle(
      {required String token, required int userId, bool registerPush = true}) {
    calls++;
    this.token = token;
    this.userId = userId;
  }
}

class _TestController extends OauthLoginController {
  _TestController(
      {required super.apple,
      required super.wechat,
      required super.gateway,
      required super.successHandler,
      super.wechatTimeout});
  String? lastBindTicket;
  int navBind = 0;
  List<String> snacks = [];
  @override
  void goToBindPhone(String bindTicket) {
    navBind++;
    lastBindTicket = bindTicket;
  }

  @override
  void showError(String msg) => snacks.add(msg);
}

void main() {
  final okChallenge = ApiResponse<String?>(success: true, data: 'raw-nonce');
  _TestController build(
          {required SdkAuthResult appleResult,
          required ApiResponse<String?> challengeResp,
          required ApiResponse<OauthLoginData> loginResp,
          _SpyHandler? handler}) =>
      _TestController(
        apple: _FakeApple(appleResult),
        wechat: _FakeWechat(appleResult),
        gateway:
            _FakeGateway(challengeResp: challengeResp, loginResp: loginResp),
        successHandler: handler ?? _SpyHandler(),
      );

  test('apple hit → successHandler.handle called', () async {
    final h = _SpyHandler();
    final c = build(
        appleResult: const SdkAuthSuccess('idtoken'),
        challengeResp: okChallenge,
        loginResp: ApiResponse(
            success: true,
            data: const OauthLoginData(token: 'jwt', userId: 9)),
        handler: h);
    await c.loginWithApple();
    expect(h.calls, 1);
    expect(h.token, 'jwt');
    expect(h.userId, 9);
    // 防重放核心不变式：传给后端的必须是原始 nonce（不是 sha256 后的值、也不是 null）。
    final gateway = c.gateway as _FakeGateway;
    expect(gateway.capturedNonce, 'raw-nonce');
    expect(gateway.capturedProvider, OauthProvider.apple);
  });
  test('apple needBind → navigate to bindPhone with ticket', () async {
    final c = build(
        appleResult: const SdkAuthSuccess('idtoken'),
        challengeResp: okChallenge,
        loginResp: ApiResponse(
            success: true,
            data: const OauthLoginData(needBind: true, bindTicket: 'bt-9')));
    await c.loginWithApple();
    expect(c.navBind, 1);
    expect(c.lastBindTicket, 'bt-9');
  });
  test('apple needMergeAuth → error snackbar, no nav', () async {
    final c = build(
        appleResult: const SdkAuthSuccess('idtoken'),
        challengeResp: okChallenge,
        loginResp: ApiResponse(
            success: true,
            data: const OauthLoginData(needMergeAuth: true)));
    await c.loginWithApple();
    expect(c.navBind, 0);
    expect(c.snacks, isNotEmpty);
  });
  test('user cancelled → silent', () async {
    final c = build(
        appleResult: const SdkAuthCancelled(),
        challengeResp: okChallenge,
        loginResp: ApiResponse(
            success: true,
            data: const OauthLoginData(token: 'x', userId: 1)));
    await c.loginWithApple();
    expect(c.navBind, 0);
    expect(c.snacks, isEmpty);
  });
  test('sdk failure → error snackbar', () async {
    final c = build(
        appleResult: const SdkAuthFailure('Apple 登录失败'),
        challengeResp: okChallenge,
        loginResp: ApiResponse(
            success: true,
            data: const OauthLoginData(token: 'x', userId: 1)));
    await c.loginWithApple();
    expect(c.snacks, isNotEmpty);
  });
  test('challenge failure → error snackbar', () async {
    final c = build(
        appleResult: const SdkAuthSuccess('idtoken'),
        challengeResp:
            ApiResponse<String?>(success: false, message: 'challenge 失败'),
        loginResp: ApiResponse(
            success: true,
            data: const OauthLoginData(token: 'x', userId: 1)));
    await c.loginWithApple();
    expect(c.snacks, isNotEmpty);
  });
  test('login api failure → error snackbar', () async {
    final c = build(
        appleResult: const SdkAuthSuccess('idtoken'),
        challengeResp: okChallenge,
        loginResp:
            ApiResponse(success: false, code: 1010, message: '第三方校验失败'));
    await c.loginWithApple();
    expect(c.snacks, isNotEmpty);
  });
  test('wechat obtainCredential timeout → error snackbar', () async {
    final c = _TestController(
      apple: _FakeApple(const SdkAuthCancelled()),
      wechat: _FakeWechat(const SdkAuthSuccess('x'), neverComplete: true),
      gateway: _FakeGateway(
          challengeResp: okChallenge,
          loginResp: ApiResponse(
              success: true,
              data: const OauthLoginData(token: 't', userId: 1))),
      successHandler: _SpyHandler(),
      wechatTimeout: const Duration(milliseconds: 20),
    );
    await c.loginWithWechat();
    expect(c.snacks, isNotEmpty); // 超时 → 失败提示
  });
}
