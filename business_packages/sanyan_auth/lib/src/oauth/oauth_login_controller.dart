import 'dart:async';

import 'package:get/get.dart';
import '../auth/login_success_handler.dart';
import 'apple_auth_provider.dart';
import 'wechat_auth_provider.dart';
import 'oauth_gateway.dart';
import 'oauth_crypto.dart';
import 'oauth_provider.dart';
import 'sdk_auth_result.dart';
import 'bind_phone_page.dart';

/// 第三方登录编排控制器：Apple / 微信取凭证 → 后端校验 → 五分支处理。
class OauthLoginController extends GetxController {
  final AppleAuthProvider apple;
  final WechatAuthProvider wechat;
  final OauthGateway gateway;
  final LoginSuccessHandler successHandler;

  /// 微信 code 经异步回调返回，超时兜底时长（可注入，默认 60s）。
  final Duration wechatTimeout;
  final loading = false.obs;

  OauthLoginController({
    required this.apple,
    required this.wechat,
    required this.gateway,
    required this.successHandler,
    this.wechatTimeout = const Duration(seconds: 60),
  });

  Future<void> loginWithApple() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final ch = await gateway.challenge();
      if (!ch.success || ch.data == null) {
        showError(ch.errMsg ?? '获取登录凭据失败');
        return;
      }
      final rawNonce = ch.data!;
      final sdk = await apple.obtainCredential(sha256Hex(rawNonce));
      await _afterSdk(sdk, provider: OauthProvider.apple, nonce: rawNonce);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loginWithWechat() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final sdk = await wechat.obtainCredential('').timeout(
            wechatTimeout,
            onTimeout: () => const SdkAuthFailure('微信登录超时，请重试'),
          );
      await _afterSdk(sdk, provider: OauthProvider.wechat, nonce: null);
    } finally {
      loading.value = false;
    }
  }

  Future<void> _afterSdk(SdkAuthResult sdk,
      {required String provider, String? nonce}) async {
    switch (sdk) {
      case SdkAuthCancelled():
        return; // 用户取消，静默
      case SdkAuthFailure(message: final m):
        showError(m);
        return;
      case SdkAuthSuccess(credential: final cred):
        final resp =
            await gateway.login(provider: provider, credential: cred, nonce: nonce);
        if (!resp.success || resp.data == null) {
          showError(resp.errMsg ?? '登录失败');
          return;
        }
        final d = resp.data!;
        if (d.needBind && d.bindTicket != null) {
          goToBindPhone(d.bindTicket!);
        } else if (d.needMergeAuth) {
          showError('该手机号已注册，请用该手机号登录后在设置里绑定');
        } else if (d.loggedIn) {
          successHandler.handle(token: d.token!, userId: d.userId!);
        } else {
          showError('登录失败');
        }
    }
  }

  // 导航 / 提示 seam（测试覆写）
  void goToBindPhone(String bindTicket) =>
      Get.to(() => BindPhonePage(bindTicket: bindTicket));
  void showError(String msg) => Get.snackbar('登录失败', msg);
}
