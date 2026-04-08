import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'register_controller.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RegisterController());
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.chevron_left, size: 28, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '创建账号',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

            // Subtitle
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: Text(
                '加入三言，开始你的 AI 陪伴之旅',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Phone
                    _buildInput(
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Text('+86', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 24, color: AppColors.border),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: c.phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                              decoration: _inputDecoration('手机号'),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Code
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: c.codeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                                decoration: _inputDecoration('验证码'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => GestureDetector(
                              onTap: c.countdown.value > 0 ? null : c.sendSms,
                              child: Container(
                                width: 110,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  c.countdown.value > 0 ? '${c.countdown.value}s' : '获取验证码',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: c.countdown.value > 0 ? AppColors.textSecondary : AppColors.accent,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Password
                    _buildInput(
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: c.passwordController,
                              obscureText: true,
                              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                              decoration: _inputDecoration('设置密码'),
                            ),
                          ),
                          const Icon(Icons.visibility_off, color: AppColors.textPlaceholder, size: 20),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nickname
                    _buildInput(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: c.nicknameController,
                          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                          decoration: _inputDecoration('昵称'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register button
                    Obx(() => GestureDetector(
                          onTap: c.isLoading.value ? null : c.register,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.buttonGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: c.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    '注册',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // Bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      '已有账号？返回登录',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '注册即代表同意《用户协议》和《隐私政策》',
                    style: TextStyle(fontSize: 11, color: AppColors.textPlaceholder),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({required Widget child}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 16),
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
    );
  }
}
