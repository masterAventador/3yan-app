/// 第三方登录 / 绑手机 共用响应模型。
/// 三态互斥：命中登录(token+userId) | 未绑(needBind+bindTicket) | 需合并(needMergeAuth)。
class OauthLoginData {
  final String? token;
  final int? userId;
  final bool needBind;
  final String? bindTicket;
  final bool needMergeAuth;
  final String? nickname;
  final String? avatar;

  const OauthLoginData({
    this.token,
    this.userId,
    this.needBind = false,
    this.bindTicket,
    this.needMergeAuth = false,
    this.nickname,
    this.avatar,
  });

  factory OauthLoginData.fromJson(Map<String, dynamic> json) => OauthLoginData(
        token: json['token'] as String?,
        userId: (json['userId'] as num?)?.toInt(),
        needBind: json['needBind'] as bool? ?? false,
        bindTicket: json['bindTicket'] as String?,
        needMergeAuth: json['needMergeAuth'] as bool? ?? false,
        nickname: json['nickname'] as String?,
        avatar: json['avatar'] as String?,
      );

  bool get loggedIn => token != null && userId != null;
}
