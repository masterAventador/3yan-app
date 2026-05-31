/// 认证相关校验（单点定义，防字面量漂移）。
abstract class AuthValidators {
  static final RegExp phoneReg = RegExp(r'^1\d{10}$');
}
