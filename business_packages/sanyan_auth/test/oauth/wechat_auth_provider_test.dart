import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_auth/src/oauth/sdk_auth_result.dart';
import 'package:sanyan_auth/src/oauth/wechat_auth_provider.dart';

/// 用可控 fake 覆写"是否安装"与"发起授权"，并手动投递回调结果。
class _FakeWechat extends WechatAuthProviderImpl {
  final bool installed;
  final WechatAuthCallbackResult deliver;
  _FakeWechat({required this.installed, required this.deliver});
  @override
  Future<bool> isInstalled() async => installed;
  @override
  Future<void> startAuth(void Function(WechatAuthCallbackResult) onResult) async {
    onResult(deliver); // 立即投递，模拟微信回调
  }
}

void main() {
  test('success delivers code', () async {
    final p = _FakeWechat(installed: true,
        deliver: const WechatAuthCallbackResult(successful: true, code: 'wxcode'));
    final r = await p.obtainCredential('');
    expect(r, isA<SdkAuthSuccess>());
    expect((r as SdkAuthSuccess).credential, 'wxcode');
  });
  test('not installed → failure', () async {
    final p = _FakeWechat(installed: false,
        deliver: const WechatAuthCallbackResult(successful: true, code: 'x'));
    final r = await p.obtainCredential('');
    expect(r, isA<SdkAuthFailure>());
  });
  test('user cancelled (errCode -2) → cancelled', () async {
    final p = _FakeWechat(installed: true,
        deliver: const WechatAuthCallbackResult(successful: false, errCode: -2));
    final r = await p.obtainCredential('');
    expect(r, isA<SdkAuthCancelled>());
  });
  test('user denied (errCode -4) → cancelled', () async {
    final p = _FakeWechat(installed: true,
        deliver: const WechatAuthCallbackResult(successful: false, errCode: -4));
    final r = await p.obtainCredential('');
    expect(r, isA<SdkAuthCancelled>());
  });
  test('failed with other errCode → failure', () async {
    final p = _FakeWechat(installed: true,
        deliver: const WechatAuthCallbackResult(successful: false, errCode: -1));
    final r = await p.obtainCredential('');
    expect(r, isA<SdkAuthFailure>());
  });
}
