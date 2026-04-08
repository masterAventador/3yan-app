import 'package:sanyan_network/sanyan_network.dart';

class ResetPasswordReq extends BaseReq {
  final String phone;
  final String code;
  final String newPassword;

  ResetPasswordReq({
    required this.phone,
    required this.code,
    required this.newPassword,
  });

  @override
  String get path => '/api/auth/password/reset';
  @override
  String get method => 'POST';
  @override
  Map<String, dynamic> toJson() => {
        'phone': phone,
        'code': code,
        'newPassword': newPassword,
      };
}
