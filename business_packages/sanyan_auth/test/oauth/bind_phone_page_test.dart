import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/src/oauth/oauth_gateway.dart';
import 'package:sanyan_auth/src/auth/login_success_handler.dart';
import 'package:sanyan_auth/src/oauth/bind_phone_page.dart';

class _NoGateway implements OauthGateway {
  @override
  Future<ApiResponse<String?>> challenge() => throw UnimplementedError();
  @override
  Future<ApiResponse<OauthLoginData>> login({
    required String provider,
    required String credential,
    String? nonce,
  }) =>
      throw UnimplementedError();
  @override
  Future<ApiResponse<OauthLoginData>> bindPhone({
    required String bindTicket,
    required String phone,
    required String code,
    String? password,
  }) =>
      throw UnimplementedError();
}

class _NoHandler implements LoginSuccessHandler {
  @override
  void handle({required String token, required int userId, bool registerPush = true}) {}
}

void main() {
  setUp(() {
    Get.put<OauthGateway>(_NoGateway());
    Get.put<LoginSuccessHandler>(_NoHandler());
  });
  tearDown(() {
    Get.reset();
  });

  testWidgets('renders phone/code/password inputs + sms + submit buttons', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: BindPhonePage(bindTicket: 'bt')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('input_bind_phone')), findsOneWidget);
    expect(find.byKey(const Key('input_bind_code')), findsOneWidget);
    expect(find.byKey(const Key('input_bind_password')), findsOneWidget);
    expect(find.byKey(const Key('btn_send_sms')), findsOneWidget);
    expect(find.byKey(const Key('btn_bind_submit')), findsOneWidget);
  });
}
