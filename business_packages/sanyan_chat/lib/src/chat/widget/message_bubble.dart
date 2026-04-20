import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../../api/models/message.dart';
import 'voice_bubble.dart';
import 'video_bubble.dart';

// 头像尺寸与气泡最大宽度约束（气泡最长不能越过对面预留的头像位）
const double _avatarSize = 40;
const double _avatarGap = 10;

/// 气泡（含语音时长对应宽度、文本软换行）可用的最大宽度：
/// 屏宽 − 两侧 pagePadding − 双侧头像 − 双侧间距
double _maxBubbleWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  return w - AuraSpacing.pagePadding * 2 - _avatarSize * 2 - _avatarGap * 2;
}

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == SenderType.user;
    final isVideo = message.contentType == ContentType.video;
    final maxW = _maxBubbleWidth(context);

    final avatar = _Avatar(isUser: isUser);

    // Column 外层套 ConstrainedBox(maxWidth: maxW)：
    // Flexible 给的最大宽度是 "Row 宽 - 自己头像 - gap"（不含对面预留），
    // 不加 ConstrainedBox 气泡会侵入对方头像应占的区域。
    // maxW = 屏宽 - 2 × pagePadding - 2 × avatar - 2 × gap，两端都预留头像位。
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isVoice)
            VoiceBubble(message: message, maxWidth: maxW)
          else if (isVideo)
            VideoBubble(isUser: isUser)
          else
            _TextBubble(message: message, isUser: isUser),
          const SizedBox(height: 4),
          _Timestamp(message: message, isUser: isUser),
        ],
      ),
    );

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: AuraSpacing.pagePadding, vertical: 3),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUser
            ? [Flexible(child: bubble), const SizedBox(width: _avatarGap), avatar]
            : [avatar, const SizedBox(width: _avatarGap), Flexible(child: bubble)],
      ),
    );
  }
}

/// 头像：AI 用爱心图标 + 薄荷渐变；用户用人形图标 + 紫色渐变
class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isUser
            ? AuraColors.userBubbleGradient
            : AuraColors.mintAzureGradient,
        border: Border.all(
          color: AuraColors.primaryFixed.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.favorite,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

// ─── Text bubble ─────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  const _TextBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 气泡与头像对齐（40）：14 × 1.3 + 11 × 2 ≈ 40
      // ⚠️ 不能设 alignment！alignment + bounded parent constraints 会让 Container 扩展到最大宽度。
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: isUser ? AuraColors.userBubbleGradient : null,
        color: isUser ? null : AuraColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 10 : 2),
          topRight: Radius.circular(isUser ? 2 : 10),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
        boxShadow: isUser
            ? null
            : [
                BoxShadow(
                  color: AuraColors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 14,
          height: 1.3,
          color: isUser ? Colors.white : AuraColors.onSurface,
        ),
      ),
    );
  }
}

// ─── Timestamp row ────────────────────────────────────────────────────────────

class _Timestamp extends StatelessWidget {
  final Message message;
  final bool isUser;
  const _Timestamp({required this.message, required this.isUser});

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(message.createdAt),
      style: TextStyle(
        fontFamily: AuraFonts.inter,
        fontSize: 10,
        color: AuraColors.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}
