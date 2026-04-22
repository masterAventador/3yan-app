import 'package:flutter/material.dart';
import '../../api/models/message_status.dart';

/// 所有消息气泡的外壳 + 状态指示层（sending / failed / sent / null）。
/// 子类（MessageBubble / VoiceBubble / VideoBubble）只负责"内容区域"
/// 通过 [child] 传入。
///
/// 状态指示布局：
/// - 用户消息（isFromAi=false）：指示在左侧、内容在右侧
/// - AI 消息（isFromAi=true）：内容在左侧、指示在右侧（AI 消息通常 status 为 null）
///
/// 状态 → 指示映射：
/// - sending：小菊花（14×14 圆形进度条）
/// - failed：红色感叹号 IconButton（点击触发 onRetry）
/// - sent / null：无指示
class MessageBubbleBase extends StatelessWidget {
  final bool isFromAi;
  final MessageStatus? status;
  final VoidCallback? onRetry;
  final Widget child;

  const MessageBubbleBase({
    super.key,
    required this.isFromAi,
    required this.status,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();
    // sent / null 状态：直接返回 child，不引入 Row 包装，保持 child 的
    // intrinsic 尺寸布局（否则 Flexible 会让 text 气泡被拉宽）。
    if (indicator == null) return child;

    return Row(
      mainAxisAlignment:
          isFromAi ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: isFromAi
          ? [Flexible(child: child), indicator]
          : [indicator, Flexible(child: child)],
    );
  }

  Widget? _buildIndicator() {
    switch (status) {
      case MessageStatus.sending:
        return const Padding(
          key: Key('bubble-sending-indicator'),
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case MessageStatus.failed:
        return IconButton(
          key: const Key('bubble-failed-indicator'),
          icon: const Icon(Icons.error, color: Colors.red, size: 20),
          onPressed: onRetry,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        );
      case MessageStatus.sent:
      case null:
        return null;
    }
  }
}
