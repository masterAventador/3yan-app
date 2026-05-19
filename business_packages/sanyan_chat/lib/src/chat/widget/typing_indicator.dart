import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

/// AI 正在输入指示器：AI 头像 + 3 个弹跳小圆点 + "正在输入"
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

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
    // 布局跟 MessageBubble 对齐，保证切换到真实 AI 消息时头像/气泡位置不跳。
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: AuraSpacing.pagePadding, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像样式与 MessageBubble 的 AI 头像保持一致（BoxShape.circle + 同款渐变 + 同款 Icon）。
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFA8E6CF), Color(0xFF7CCFC6)],
              ),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "打字中"气泡：高度与 VoiceBubble 一致（40），切换时气泡尺寸不突变
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AuraColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: AuraColors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0.0),
                    const SizedBox(width: 3),
                    _buildDot(0.2),
                    const SizedBox(width: 3),
                    _buildDot(0.4),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 透明占位，撑出跟 _Timestamp 相同的高度，切换到真实消息时整体高度不变
              Text(
                '00:00',
                style: TextStyle(
                  fontFamily: AuraFonts.inter,
                  fontSize: 10,
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
