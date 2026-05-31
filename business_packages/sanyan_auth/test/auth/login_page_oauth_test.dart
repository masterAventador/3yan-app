import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/src/oauth/apple_auth_provider.dart';
import 'package:sanyan_auth/src/oauth/wechat_auth_provider.dart';
import 'package:sanyan_auth/src/oauth/oauth_gateway.dart';
import 'package:sanyan_auth/src/oauth/sdk_auth_result.dart';
import 'package:sanyan_auth/src/auth/login_success_handler.dart';
import 'package:sanyan_auth/src/oauth/oauth_login_controller.dart';
import 'package:sanyan_auth/src/auth/login_page.dart';

class _NoApple implements AppleAuthProvider {
  @override
  Future<SdkAuthResult> obtainCredential(String n) => throw UnimplementedError();
}

class _NoWechat implements WechatAuthProvider {
  @override
  Future<SdkAuthResult> obtainCredential(String n) => throw UnimplementedError();
}

class _NoGateway implements OauthGateway {
  @override
  Future<ApiResponse<String?>> challenge() => throw UnimplementedError();
  @override
  Future<ApiResponse<OauthLoginData>> login(
          {required String provider, required String credential, String? nonce}) =>
      throw UnimplementedError();
  @override
  Future<ApiResponse<OauthLoginData>> bindPhone(
          {required String bindTicket,
          required String phone,
          required String code,
          String? password}) =>
      throw UnimplementedError();
}

class _NoHandler implements LoginSuccessHandler {
  @override
  void handle({required String token, required int userId, bool registerPush = true}) =>
      throw UnimplementedError();
}

class _SpyOauth extends OauthLoginController {
  _SpyOauth()
      : super(
            apple: _NoApple(),
            wechat: _NoWechat(),
            gateway: _NoGateway(),
            successHandler: _NoHandler());
  int appleCalls = 0;
  int wechatCalls = 0;
  @override
  Future<void> loginWithApple() async => appleCalls++;
  @override
  Future<void> loginWithWechat() async => wechatCalls++;
}

void main() {
  testWidgets('login page shows Apple & WeChat buttons; taps route to controller',
      (tester) async {
    final spy = _SpyOauth();
    Get.put<OauthLoginController>(spy);
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_oauth_apple')), findsOneWidget);
    expect(find.byKey(const Key('btn_oauth_wechat')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('btn_oauth_apple')));
    await tester.tap(find.byKey(const Key('btn_oauth_apple')));
    await tester.pump();
    expect(spy.appleCalls, 1);

    await tester.ensureVisible(find.byKey(const Key('btn_oauth_wechat')));
    await tester.tap(find.byKey(const Key('btn_oauth_wechat')));
    await tester.pump();
    expect(spy.wechatCalls, 1);

    Get.delete<OauthLoginController>();
  });
}
