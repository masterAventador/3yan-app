import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'message_bubble_shell.dart';

/// AI "正在输入" 占位气泡：在 [MessageBubbleShell] 内塞 3 个弹跳小圆点。
/// 头像 / 气泡边框 / 时间戳占位全部走 shell，跟真实 AI 消息切换时不跳。
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessageBubbleShell(
      isUser: false,
      // createdAt null → 时间戳透明占位，保持高度一致
      child: _ThreeDotsAnimation(),
    );
  }
}

class _ThreeDotsAnimation extends StatefulWidget {
  const _ThreeDotsAnimation();

  @override
  State<_ThreeDotsAnimation> createState() => _ThreeDotsAnimationState();
}

class _ThreeDotsAnimationState extends State<_ThreeDotsAnimation>
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0.0),
        const SizedBox(width: 3),
        _buildDot(0.2),
        const SizedBox(width: 3),
        _buildDot(0.4),
      ],
    );
  }
}
