import 'package:sanyan_network/sanyan_network.dart';

class SendSmsReq extends BaseReq {
  final String phone;

  SendSmsReq({required this.phone});

  @override
  String get path => '/api/auth/sms/send';
  @override
  String get method => 'POST';
  @override
  Map<String, dynamic> toJson() => {'phone': phone};
}
