import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'package:sanyan_user/sanyan_user.dart';

class RegisterController extends GetxController {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  final isLoading = false.obs;
  final countdown = 0.obs;
  Timer? _countdownTimer;

  String? validatePhone(String phone) {
    if (phone.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) return '手机号格式不正确';
    return null;
  }

  String? validateCode(String code) {
    if (code.isEmpty) return '请输入验证码';
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return '请输入密码';
    if (password.length < 6) return '密码至少6位';
    return null;
  }

  Future<void> sendSms() async {
    final phone = phoneController.text.trim();
    final phoneError = validatePhone(phone);
    if (phoneError != null) {
      Get.snackbar('提示', phoneError);
      return;
    }

    try {
      final resp = await AuthApi.sendSms(phone);
      if (resp.success) {
        _startCountdown();
        Get.snackbar('提示', '验证码已发送');
      } else {
        Get.snackbar('发送失败', resp.errMsg ?? '未知错误');
      }
    } catch (e) {
      Get.snackbar('发送失败', '网络错误，请稍后重试');
    }
  }

  void _startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown.value--;
      if (countdown.value <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> register() async {
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    final nickname = nicknameController.text.trim();

    final phoneError = validatePhone(phone);
    if (phoneError != null) {
      Get.snackbar('提示', phoneError);
      return;
    }
    final codeError = validateCode(code);
    if (codeError != null) {
      Get.snackbar('提示', codeError);
      return;
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      Get.snackbar('提示', passwordError);
      return;
    }

    isLoading.value = true;
    try {
      final resp = await AuthApi.register(
        phone: phone,
        code: code,
        password: password,
        nickname: nickname.isNotEmpty ? nickname : null,
      );
      if (resp.success && resp.data != null) {
        LocalStorage.token = resp.data!['token'];
        LocalStorage.userId = resp.data!['userId'];
        Get.find<WsClient>().connect();
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar('注册失败', resp.errMsg ?? '未知错误');
      }
    } catch (e) {
      Get.snackbar('注册失败', '网络错误，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.onClose();
  }
}
