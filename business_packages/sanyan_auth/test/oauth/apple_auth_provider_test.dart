import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sanyan_auth/src/oauth/sdk_auth_result.dart';
import 'package:sanyan_auth/src/oauth/apple_auth_provider.dart';

class _FakeApple extends AppleAuthProviderImpl {
  final Object? throwThis;
  final String? returnToken;
  _FakeApple({this.throwThis, this.returnToken});
  @override
  Future<String?> rawIdentityToken(String nonceSha256) async {
    if (throwThis != null) throw throwThis!;
    return returnToken;
  }
}

void main() {
  test('returns success credential when plugin yields identityToken', () async {
    final p = _FakeApple(returnToken: 'idtoken-xyz');
    final r = await p.obtainCredential('sha');
    expect(r, isA<SdkAuthSuccess>());
    expect((r as SdkAuthSuccess).credential, 'idtoken-xyz');
  });
  test('maps canceled exception to SdkAuthCancelled', () async {
    final p = _FakeApple(
      throwThis: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled, message: 'user canceled'),
    );
    final r = await p.obtainCredential('sha');
    expect(r, isA<SdkAuthCancelled>());
  });
  test('maps null token to SdkAuthFailure', () async {
    final p = _FakeApple(returnToken: null);
    final r = await p.obtainCredential('sha');
    expect(r, isA<SdkAuthFailure>());
  });
  test('maps other error to SdkAuthFailure', () async {
    final p = _FakeApple(throwThis: Exception('boom'));
    final r = await p.obtainCredential('sha');
    expect(r, isA<SdkAuthFailure>());
  });
}
