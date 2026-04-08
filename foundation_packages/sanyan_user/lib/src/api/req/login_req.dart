import 'package:sanyan_network/sanyan_network.dart';

class LoginReq extends BaseReq {
  final String phone;
  final String password;

  LoginReq({required this.phone, required this.password});

  @override
  String get path => '/api/auth/login';
  @override
  String get method => 'POST';
  @override
  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}
