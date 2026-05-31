/// 第三方登录 provider 标识（与后端 Provider enum 对齐，单点定义防字面量漂移）。
abstract class OauthProvider {
  static const String apple = 'APPLE';
  static const String wechat = 'WECHAT';
}
