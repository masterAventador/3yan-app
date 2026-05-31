import 'dart:async';
import 'package:fluwx/fluwx.dart';
import 'sdk_auth_result.dart';

/// 桥接微信回调用的中间结果（把 fluwx 的 WeChatAuthResponse 归一化，便于 fake）。
class WechatAuthCallbackResult {
  final bool successful;
  final String? code;
  final int? errCode;
  const WechatAuthCallbackResult({required this.successful, this.code, this.errCode});
}

abstract class WechatAuthProvider {
  Future<SdkAuthResult> obtainCredential(String unusedNonce);
}

class WechatAuthProviderImpl implements WechatAuthProvider {
  /// 延迟创建：Fluwx() 构造会注册 method-channel 监听，
  /// fake 覆写了 isInstalled/startAuth 两个 seam 后就不会触碰它，便于纯 Dart 测试。
  late final Fluwx _fluwx = Fluwx();

  /// seam：是否安装微信
  Future<bool> isInstalled() => _fluwx.isWeChatInstalled;

  /// seam：发起授权并把回调归一化后交给 [onResult]（只触发一次）。
  Future<void> startAuth(void Function(WechatAuthCallbackResult) onResult) async {
    late final FluwxCancelable cancelable;
    cancelable = _fluwx.addSubscriber((response) {
      if (response is WeChatAuthResponse) {
        onResult(WechatAuthCallbackResult(
          successful: response.isSuccessful,
          code: response.code,
          errCode: response.errCode,
        ));
        cancelable.cancel();
      }
    });
    try {
      await _fluwx.authBy(which: NormalAuth(scope: 'snsapi_userinfo', state: 'sanyan_login'));
    } catch (_) {
      cancelable.cancel(); // 发起失败时取消订阅，避免泄漏
      rethrow;
    }
  }

  @override
  Future<SdkAuthResult> obtainCredential(String unusedNonce) async {
    if (!await isInstalled()) return const SdkAuthFailure('未安装微信');
    final completer = Completer<SdkAuthResult>();
    await startAuth((r) {
      if (completer.isCompleted) return;
      if (r.successful && r.code != null) {
        completer.complete(SdkAuthSuccess(r.code!));
      } else if (r.errCode == -2 || r.errCode == -4) {
        // -2 用户取消 / -4 用户拒绝授权
        completer.complete(const SdkAuthCancelled());
      } else {
        completer.complete(SdkAuthFailure('微信登录失败 (${r.errCode})'));
      }
    });
    return completer.future;
  }
}
