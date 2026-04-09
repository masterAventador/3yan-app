import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import '../../models/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _player.play(UrlSource(widget.message.mediaUrl!));
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.senderType == 'user';
    final isVoice = widget.message.isVoice && !isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: isVoice ? _buildVoiceBubble() : _buildTextBubble(isUser),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble() {
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.aiBubble,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: AppColors.brandButton,
              size: 32,
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.graphic_eq,
              color: _isPlaying ? AppColors.brandButton : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser ? AppColors.buttonGradient : null,
        color: isUser ? null : AppColors.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 16 : 4),
          topRight: Radius.circular(isUser ? 4 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
      ),
      child: Text(
        widget.message.content,
        style: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}
