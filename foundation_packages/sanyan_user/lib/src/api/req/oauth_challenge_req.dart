import 'package:sanyan_network/sanyan_network.dart';

/// POST /api/auth/oauth/challenge：登录前拿一次性 nonce（S8 防重放）。
/// 响应 data 为 {nonce: "..."}，AuthApi 取其中的 nonce 字段。
class OauthChallengeReq extends BaseReq {
  @override
  String get path => '/api/auth/oauth/challenge';

  @override
  String get method => 'POST';

  @override
  Map<String, dynamic> toJson() => {};
}
