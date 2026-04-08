import 'package:sanyan_network/sanyan_network.dart';

class AuthApi {
  static final _client = ApiClient();

  static Future<ApiResponse> sendSms(String phone) =>
      _client.post('/api/auth/sms/send', data: {'phone': phone});

  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String phone,
    required String code,
    required String password,
    String? nickname,
  }) =>
      _client.post(
        '/api/auth/register',
        data: {'phone': phone, 'code': code, 'password': password, 'nickname': nickname},
        fromData: (d) => d as Map<String, dynamic>,
      );

  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String phone,
    required String password,
  }) =>
      _client.post(
        '/api/auth/login',
        data: {'phone': phone, 'password': password},
        fromData: (d) => d as Map<String, dynamic>,
      );

  static Future<ApiResponse> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) =>
      _client.post(
        '/api/auth/password/reset',
        data: {'phone': phone, 'code': code, 'newPassword': newPassword},
      );
}
