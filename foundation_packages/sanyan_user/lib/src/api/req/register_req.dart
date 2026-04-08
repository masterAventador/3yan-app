import 'package:sanyan_network/sanyan_network.dart';

class RegisterReq extends BaseReq {
  final String phone;
  final String code;
  final String password;
  final String? nickname;

  RegisterReq({
    required this.phone,
    required this.code,
    required this.password,
    this.nickname,
  });

  @override
  String get path => '/api/auth/register';
  @override
  String get method => 'POST';
  @override
  Map<String, dynamic> toJson() => {
        'phone': phone,
        'code': code,
        'password': password,
        'nickname': nickname,
      };
}
