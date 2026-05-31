import 'package:sanyan_network/sanyan_network.dart';

/// POST /api/auth/oauth/login：第三方登录。
/// provider 大写 'APPLE' / 'WECHAT'；nonce 仅 Apple 传，微信传 null（省略字段）。
class OauthLoginReq extends BaseReq {
  final String provider; // 'APPLE' | 'WECHAT'
  final String credential;
  final String? nonce;

  OauthLoginReq({required this.provider, required this.credential, this.nonce});

  @override
  String get path => '/api/auth/oauth/login';

  @override
  String get method => 'POST';

  @override
  Map<String, dynamic> toJson() => {
        'provider': provider,
        'credential': credential,
        if (nonce != null) 'nonce': nonce,
      };
}
