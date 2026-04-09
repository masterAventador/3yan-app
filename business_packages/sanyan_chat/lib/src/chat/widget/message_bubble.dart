import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../../models/message.dart';
import 'voice_bubble.dart';
import 'video_bubble.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == 'user';
    final isVideo = message.contentType == ContentType.video;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AuraColors.mintAzureGradient,
                border: Border.all(
                  color: AuraColors.primaryFixed.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],

          // Bubble content
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.isVoice)
                  VoiceBubble(message: message)
                else if (isVideo)
                  VideoBubble(isUser: isUser)
                else
                  _TextBubble(message: message, isUser: isUser),
                const SizedBox(height: 4),
                _Timestamp(message: message, isUser: isUser),
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 10),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser ? AuraColors.userBubbleGradient : null,
        color: isUser ? null : AuraColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 16 : 0),
          topRight: Radius.circular(isUser ? 0 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
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
        style: GoogleFonts.manrope(
          fontSize: 15,
          height: 1.5,
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
    final timeStr = _formatTime(message.createdAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUser) ...[
          const Icon(
            Icons.done_all,
            size: 12,
            color: AuraColors.primary,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          timeStr,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AuraColors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
