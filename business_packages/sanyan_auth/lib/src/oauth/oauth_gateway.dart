import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';

/// OAuth 后端调用网关（DI 测试 seam）。控制器依赖本接口，单测用 fake 注入。
abstract class OauthGateway {
  Future<ApiResponse<String?>> challenge();

  Future<ApiResponse<OauthLoginData>> login({
    required String provider,
    required String credential,
    String? nonce,
  });

  Future<ApiResponse<OauthLoginData>> bindPhone({
    required String bindTicket,
    required String phone,
    required String code,
    String? password,
  });
}

class OauthGatewayImpl implements OauthGateway {
  @override
  Future<ApiResponse<String?>> challenge() => AuthApi.oauthChallenge();

  @override
  Future<ApiResponse<OauthLoginData>> login({
    required String provider,
    required String credential,
    String? nonce,
  }) =>
      AuthApi.oauthLogin(
        provider: provider,
        credential: credential,
        nonce: nonce,
      );

  @override
  Future<ApiResponse<OauthLoginData>> bindPhone({
    required String bindTicket,
    required String phone,
    required String code,
    String? password,
  }) =>
      AuthApi.oauthBindPhone(
        bindTicket: bindTicket,
        phone: phone,
        code: code,
        password: password,
      );
}
