import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'sdk_auth_result.dart';

/// Apple 登录凭证获取抽象（可注入 / 可 fake）。
abstract class AppleAuthProvider {
  /// [nonceSha256] = sha256Hex(challenge 拿到的原始 nonce)。
  Future<SdkAuthResult> obtainCredential(String nonceSha256);
}

class AppleAuthProviderImpl implements AppleAuthProvider {
  /// 薄平台调用 seam——测试覆写它，避免依赖真插件。
  Future<String?> rawIdentityToken(String nonceSha256) async {
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonceSha256,
    );
    return cred.identityToken;
  }

  @override
  Future<SdkAuthResult> obtainCredential(String nonceSha256) async {
    try {
      final token = await rawIdentityToken(nonceSha256);
      if (token == null) return const SdkAuthFailure('Apple 未返回凭证');
      return SdkAuthSuccess(token);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SdkAuthCancelled();
      }
      return const SdkAuthFailure('Apple 登录失败');
    } catch (_) {
      return const SdkAuthFailure('Apple 登录失败');
    }
  }
}
