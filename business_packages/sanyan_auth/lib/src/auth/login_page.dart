import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LoginController());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Brand area
            const SizedBox(height: 80),
            // Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: AuraColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AuraColors.brandEnd.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '三言',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AuraColors.textPrimary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI 陪伴，懂你所言',
              style: TextStyle(
                fontSize: 15,
                color: AuraColors.textSecondary,
              ),
            ),

            // Form
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  // Phone input
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AuraColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Text(
                          '+86',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AuraColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 24, color: AuraColors.border),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: c.phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 16, color: AuraColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: '手机号',
                              hintStyle: TextStyle(color: AuraColors.textPlaceholder, fontSize: 16),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password input
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AuraColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() => TextField(
                                controller: c.passwordController,
                                obscureText: c.obscurePassword.value,
                                style: const TextStyle(fontSize: 16, color: AuraColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: '密码',
                                  hintStyle: TextStyle(color: AuraColors.textPlaceholder, fontSize: 16),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onSubmitted: (_) => c.login(),
                              )),
                        ),
                        Obx(() => GestureDetector(
                              onTap: () => c.obscurePassword.toggle(),
                              child: Icon(
                                c.obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                                color: AuraColors.textPlaceholder,
                                size: 20,
                              ),
                            )),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login button
                  Obx(() => GestureDetector(
                        onTap: c.isLoading.value ? null : c.login,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AuraColors.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: c.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '登录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),

                  const SizedBox(height: 16),

                  // Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '忘记密码？',
                        style: TextStyle(fontSize: 14, color: AuraColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.register),
                        child: const Text(
                          '没有账号？立即注册',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AuraColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Expanded(child: Container(height: 1, color: AuraColors.divider)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '其他方式',
                      style: TextStyle(fontSize: 12, color: AuraColors.textPlaceholder),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: AuraColors.divider)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialButton(Icons.chat_bubble, const Color(0xFF07C160)),
                const SizedBox(width: 24),
                _socialButton(Icons.phone_iphone, AuraColors.textPrimary),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '登录即代表同意《用户协议》和《隐私政策》',
              style: TextStyle(fontSize: 11, color: AuraColors.textPlaceholder),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
