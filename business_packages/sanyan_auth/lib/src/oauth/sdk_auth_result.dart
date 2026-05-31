/// 第三方 SDK 取凭证的三态结果。
sealed class SdkAuthResult {
  const SdkAuthResult();
}

class SdkAuthSuccess extends SdkAuthResult {
  final String credential; // Apple=identityToken / WeChat=code
  const SdkAuthSuccess(this.credential);
}

class SdkAuthCancelled extends SdkAuthResult {
  const SdkAuthCancelled();
}

class SdkAuthFailure extends SdkAuthResult {
  final String message;
  const SdkAuthFailure(this.message);
}
