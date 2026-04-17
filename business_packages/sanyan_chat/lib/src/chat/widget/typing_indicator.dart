import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

/// AI 正在输入指示器：AI 头像 + 3 个弹跳小圆点 + "正在输入"
class TypingIndicator extends StatefulWidget {
  final String characterName;
  const TypingIndicator({super.key, required this.characterName});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 每个 dot 错开相位（0 / 0.2 / 0.4），形成连续弹跳
        final phase = (_controller.value - delay) % 1.0;
        // 只在前半相位做上弹动作，后半回落（sin 0~π）
        final progress = phase < 0.5 ? phase * 2 : 0.0;
        final dy = -5 * math.sin(progress * math.pi);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AuraColors.primary.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AuraSpacing.pagePadding, vertical: 8),
      child: Row(
        children: [
          // 左侧 AI 头像（跟 MessageBubble 风格一致）
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AuraColors.mintAzureGradient,
              border: Border.all(
                color: AuraColors.primaryFixed.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          // 弹跳圆点 + 文字
          _buildDot(0.0),
          const SizedBox(width: 3),
          _buildDot(0.2),
          const SizedBox(width: 3),
          _buildDot(0.4),
          const SizedBox(width: 8),
          Text(
            '${widget.characterName} 正在输入',
            style: TextStyle(
              fontFamily: AuraFonts.inter,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: AuraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
