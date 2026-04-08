import 'package:sanyan_network/sanyan_network.dart';
import 'req/send_sms_req.dart';
import 'req/register_req.dart';
import 'req/login_req.dart';
import 'req/reset_password_req.dart';

class AuthApi {
  static final _client = ApiClient();

  static Future<ApiResponse> sendSms(String phone) =>
      _client.send(SendSmsReq(phone: phone));

  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String phone,
    required String code,
    required String password,
    String? nickname,
  }) =>
      _client.send(
        RegisterReq(phone: phone, code: code, password: password, nickname: nickname),
        fromData: (d) => d as Map<String, dynamic>,
      );

  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String phone,
    required String password,
  }) =>
      _client.send(
        LoginReq(phone: phone, password: password),
        fromData: (d) => d as Map<String, dynamic>,
      );

  static Future<ApiResponse> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) =>
      _client.send(ResetPasswordReq(phone: phone, code: code, newPassword: newPassword));
}
