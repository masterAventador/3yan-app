import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'oauth_gateway.dart';
import '../auth/login_success_handler.dart';
import 'bind_phone_controller.dart';

/// 第三方登录后绑定手机号页。
class BindPhonePage extends StatefulWidget {
  final String bindTicket;
  const BindPhonePage({super.key, required this.bindTicket});

  @override
  State<BindPhonePage> createState() => _BindPhonePageState();
}

class _BindPhonePageState extends State<BindPhonePage> {
  late final BindPhoneController c;
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    c = Get.put(
      BindPhoneController(
        bindTicket: widget.bindTicket,
        gateway: Get.find<OauthGateway>(),
        successHandler: Get.find<LoginSuccessHandler>(),
      ),
      tag: widget.bindTicket,
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    Get.delete<BindPhoneController>(tag: widget.bindTicket);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    const Center(
                      child: Text(
                        '绑定手机号',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AuraColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        '绑定手机号后即可完成登录',
                        style: TextStyle(
                          fontSize: 14,
                          color: AuraColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Phone input
                    AuraInput(
                      key: const Key('input_bind_phone'),
                      controller: _phoneCtrl,
                      label: '手机号',
                      hintText: '请输入手机号',
                      leadingIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => c.phone.value = v.trim(),
                    ),
                    const SizedBox(height: 16),

                    // Code row: input + send button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AuraInput(
                            key: const Key('input_bind_code'),
                            controller: _codeCtrl,
                            label: '验证码',
                            hintText: '请输入验证码',
                            leadingIcon: Icons.sms_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => c.code.value = v.trim(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => AuraSmsCodeButton(
                              key: const Key('btn_send_sms'),
                              countdown: c.countdown.value,
                              onTap: c.sendSms,
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password input (optional, for existing account)
                    AuraInput(
                      key: const Key('input_bind_password'),
                      controller: _passwordCtrl,
                      label: '密码',
                      hintText: '已有账号时填写',
                      leadingIcon: Icons.lock_outline,
                      obscureText: true,
                      onChanged: (v) => c.password.value = v,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    Obx(() => AuraButton(
                          key: const Key('btn_bind_submit'),
                          label: '绑定并登录',
                          onPressed: c.submitting.value ? null : c.submit,
                          isLoading: c.submitting.value,
                        )),
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
