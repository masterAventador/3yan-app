import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../../api/models/message.dart';
import 'message_bubble_shell.dart';

/// 文本消息气泡：在 [MessageBubbleShell] 内塞一个 Text 作为内容。
/// 头像 / 气泡边框 / status indicator / 时间戳全部由 shell 负责。
class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRetry;
  const MessageBubble({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == SenderType.user;
    return MessageBubbleShell(
      isUser: isUser,
      status: message.status,
      createdAt: message.createdAt,
      onRetry: onRetry,
      child: Text(
        message.content,
        style: TextStyle(
          color: isUser ? Colors.white : AuraColors.primary,
          fontSize: 16,
          height: 1.35,
        ),
      ),
    );
  }
}
