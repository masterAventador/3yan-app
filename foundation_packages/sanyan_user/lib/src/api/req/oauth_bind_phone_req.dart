import 'package:sanyan_network/sanyan_network.dart';

/// POST /api/auth/oauth/bind-phone：第三方登录后绑定手机号建号。
/// password 可空（省略字段）。
class OauthBindPhoneReq extends BaseReq {
  final String bindTicket;
  final String phone;
  final String code;
  final String? password;

  OauthBindPhoneReq({
    required this.bindTicket,
    required this.phone,
    required this.code,
    this.password,
  });

  @override
  String get path => '/api/auth/oauth/bind-phone';

  @override
  String get method => 'POST';

  @override
  Map<String, dynamic> toJson() => {
        'bindTicket': bindTicket,
        'phone': phone,
        'code': code,
        if (password != null) 'password': password,
      };
}
