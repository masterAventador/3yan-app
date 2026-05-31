import 'package:flutter/material.dart';
import '../aura_colors.dart';

/// 短信验证码获取按钮。
///
/// [countdown] > 0 时显示 "${countdown}s" 并禁用点击；
/// 为 0 时显示 "获取验证码" 并可点击触发 [onTap]。
///
/// 组件内部不包 Obx——倒计时通常是 rx，由调用方在外层用 Obx 包裹后传入 [countdown]。
class AuraSmsCodeButton extends StatelessWidget {
  final int countdown;
  final VoidCallback? onTap;

  const AuraSmsCodeButton({
    super.key,
    required this.countdown,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: countdown > 0 ? null : onTap,
      child: Container(
        height: 56,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: countdown > 0 ? AuraColors.outlineVariant : AuraColors.primary,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          countdown > 0 ? '${countdown}s' : '获取验证码',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: countdown > 0 ? AuraColors.outlineVariant : AuraColors.primary,
          ),
        ),
      ),
    );
  }
}
