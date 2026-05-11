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
                        height: 56,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Center(
                      child: Text(
                        '加入三言',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AuraColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    const Center(
                      child: Text(
                        '填写信息创建你的账号',
                        style: TextStyle(
                          fontSize: 14,
                          color: AuraColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Nickname input
                    AuraInput(
                      controller: c.nicknameController,
                      label: '昵称',
                      hintText: '请输入昵称',
                      leadingIcon: Icons.person_outline,
                    ),

                    const SizedBox(height: 16),

                    // Phone input
                    AuraInput(
                      controller: c.phoneController,
                      label: '手机号',
                      hintText: '请输入手机号',
                      leadingIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    // Code row: input + button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AuraInput(
                            controller: c.codeController,
                            label: '验证码',
                            hintText: '请输入验证码',
                            leadingIcon: Icons.sms_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => GestureDetector(
                              onTap: c.countdown.value > 0 ? null : c.sendSms,
                              child: Container(
                                height: 56,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: c.countdown.value > 0
                                        ? AuraColors.outlineVariant
                                        : AuraColors.primary,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  c.countdown.value > 0
                                      ? '${c.countdown.value}s'
                                      : '获取验证码',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c.countdown.value > 0
                                        ? AuraColors.outlineVariant
                                        : AuraColors.primary,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Password input
                    AuraInput(
                      controller: c.passwordController,
                      label: '密码',
                      hintText: '请设置密码',
                      leadingIcon: Icons.lock_outline,
                      obscureText: true,
                    ),

                    const SizedBox(height: 24),

                    // Register button
                    Obx(() => AuraButton(
                          label: '注册',
                          onPressed: c.isLoading.value ? null : c.register,
                          isLoading: c.isLoading.value,
                        )),

                    const SizedBox(height: 24),

                    // Back to login link
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: AuraColors.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(text: '已有账号？ '),
                              TextSpan(
                                text: '返回登录',
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
