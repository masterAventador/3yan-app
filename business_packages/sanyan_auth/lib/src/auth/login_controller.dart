import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'package:sanyan_user/sanyan_user.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController(text: '13900001111');
  final passwordController = TextEditingController(text: '111111');
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  String? validatePhone(String phone) {
    if (phone.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) return '手机号格式不正确';
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return '请输入密码';
    return null;
  }

  Future<void> login() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    final phoneError = validatePhone(phone);
    if (phoneError != null) {
      Get.snackbar('提示', phoneError);
      return;
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      Get.snackbar('提示', passwordError);
      return;
    }

    isLoading.value = true;
    try {
      final resp = await AuthApi.login(phone: phone, password: password);
      if (resp.success && resp.data != null) {
        LocalStorage.token = resp.data!['token'];
        LocalStorage.userId = resp.data!['userId'];
        Get.find<WsClient>().connect();
        Get.offAllNamed(AppRoutes.chat);
      } else {
        Get.snackbar('登录失败', resp.errMsg ?? '未知错误');
      }
    } catch (e) {
      Get.snackbar('登录失败', '网络错误，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
