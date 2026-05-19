import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_util/sanyan_util.dart';
import '../../api/models/message.dart';
import '../../api/models/message_status.dart';

const double _avatarSize = 40;
const double _avatarGap = 10;

double _maxBubbleWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  return w - AuraSpacing.pagePadding * 2 - (_avatarSize + _avatarGap) * 2;
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRetry;
  const MessageBubble({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == SenderType.user;
    final maxW = _maxBubbleWidth(context);

    final avatar = _Avatar(isUser: isUser);
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TextBubbleWithStatus(message: message, isUser: isUser, onRetry: onRetry),
          const SizedBox(height: 4),
          _Timestamp(createdAt: message.createdAt),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AuraSpacing.pagePadding, vertical: 3),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUser
            ? [Flexible(child: bubble), const SizedBox(width: _avatarGap), avatar]
            : [avatar, const SizedBox(width: _avatarGap), Flexible(child: bubble)],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? const [Color(0xFF9F7AEA), Color(0xFFCD7BE5)]
              : const [Color(0xFFA8E6CF), Color(0xFF7CCFC6)],
        ),
      ),
      child: Icon(isUser ? Icons.person : Icons.favorite, color: Colors.white, size: 20),
    );
  }
}

class _TextBubbleWithStatus extends StatelessWidget {
  final Message message;
  final bool isUser;
  final VoidCallback? onRetry;
  const _TextBubbleWithStatus({required this.message, required this.isUser, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUser ? AuraColors.primary : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isUser ? Colors.white : AuraColors.primary,
          fontSize: 16,
          height: 1.35,
        ),
      ),
    );

    final indicator = _statusIndicator();
    if (indicator == null) return bubble;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isUser
          ? [indicator, const SizedBox(width: 6), Flexible(child: bubble)]
          : [Flexible(child: bubble), const SizedBox(width: 6), indicator],
    );
  }

  Widget? _statusIndicator() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary),
        );
      case MessageStatus.failed:
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.error, color: Colors.red, size: 18),
          onPressed: onRetry,
        );
      case MessageStatus.sent:
      case null:
        return null;
    }
  }
}

class _Timestamp extends StatelessWidget {
  final String createdAt;
  const _Timestamp({required this.createdAt});
  @override
  Widget build(BuildContext context) {
    return Text(
      DateUtil.formatHHmm(createdAt),
      style: const TextStyle(fontSize: 11, color: Colors.grey),
    );
  }
}
