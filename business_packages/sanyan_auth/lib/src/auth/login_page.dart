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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF73F1E4),
              Color(0xFFE2FFFF),
              Color(0xFFAED9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: GlassPanel(
                borderRadius: 16,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'packages/sanyan_auth/assets/images/logo.png',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Center(
                      child: Text(
                        '走进更温暖的连接方式',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AuraColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Phone input
                    AuraInput(
                      controller: c.phoneController,
                      label: '手机号',
                      hintText: '请输入手机号',
                      leadingIcon: Icons.alternate_email,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // Password input with toggle
                    Obx(() => AuraInput(
                          controller: c.passwordController,
                          label: '密码',
                          hintText: '请输入密码',
                          leadingIcon: Icons.lock_outline,
                          obscureText: c.obscurePassword.value,
                          onSubmitted: (_) => c.login(),
                          suffix: GestureDetector(
                            onTap: () => c.obscurePassword.toggle(),
                            child: Icon(
                              c.obscurePassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AuraColors.outlineVariant,
                              size: 20,
                            ),
                          ),
                        )),

                    const SizedBox(height: 28),

                    // Login button
                    Obx(() => AuraButton(
                          label: '登录',
                          onPressed: c.isLoading.value ? null : c.login,
                          isLoading: c.isLoading.value,
                          trailingIcon: Icons.arrow_forward,
                        )),

                    const SizedBox(height: 32),

                    // Thin divider
                    Divider(
                      color: AuraColors.outlineVariant.withValues(alpha: 0.10),
                      thickness: 1,
                    ),

                    const SizedBox(height: 24),

                    // Forget password
                    Center(
                      child: Text(
                        '忘记密码?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AuraColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.register),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: AuraColors.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(text: '还没有账号？ '),
                              TextSpan(
                                text: '立即注册',
                                style: TextStyle(
                                  color: AuraColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
