import 'dart:async';
import 'package:get/get.dart';
import 'package:sanyan_user/sanyan_user.dart';
import '../auth/auth_validators.dart';
import '../auth/login_success_handler.dart';
import 'oauth_gateway.dart';

class BindPhoneController extends GetxController {
  final String bindTicket;
  final OauthGateway gateway;
  final LoginSuccessHandler successHandler;

  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;
  final countdown = 0.obs;
  final submitting = false.obs;
  Timer? _timer;

  BindPhoneController({
    required this.bindTicket,
    required this.gateway,
    required this.successHandler,
  });

  Future<void> sendSms() async {
    if (countdown.value > 0) return;
    if (!AuthValidators.phoneReg.hasMatch(phone.value)) {
      showError('请输入正确的手机号');
      return;
    }
    final ok = await sendSmsApi(phone.value);
    if (ok) _startCountdown();
  }

  Future<void> submit() async {
    if (submitting.value) return;
    if (!AuthValidators.phoneReg.hasMatch(phone.value)) {
      showError('请输入正确的手机号');
      return;
    }
    if (code.value.isEmpty) {
      showError('请输入验证码');
      return;
    }
    submitting.value = true;
    try {
      final resp = await gateway.bindPhone(
        bindTicket: bindTicket,
        phone: phone.value,
        code: code.value,
        password: password.value.isEmpty ? null : password.value,
      );
      if (!resp.success || resp.data == null) {
        showError(resp.errMsg ?? '绑定失败');
        return;
      }
      final d = resp.data!;
      if (d.needMergeAuth) {
        showInfo('该手机号已注册，请输入该账号密码以验证本人，或用该手机号登录后在设置里绑定');
      } else if (d.loggedIn) {
        successHandler.handle(token: d.token!, userId: d.userId!);
      } else {
        showError('绑定失败');
      }
    } finally {
      submitting.value = false;
    }
  }

  void _startCountdown() {
    countdown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown.value <= 0) {
        t.cancel();
        return;
      }
      countdown.value--;
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // 副作用 seam（测试可覆写）
  Future<bool> sendSmsApi(String phone) async {
    final resp = await AuthApi.sendSms(phone);
    if (!resp.success) showError(resp.errMsg ?? '验证码发送失败');
    return resp.success;
  }

  void showError(String msg) => Get.snackbar('提示', msg);
  void showInfo(String msg) => Get.snackbar('需要验证', msg);
}
