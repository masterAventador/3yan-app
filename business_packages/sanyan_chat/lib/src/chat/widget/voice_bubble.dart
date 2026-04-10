import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../../models/message.dart';
import '../chat_controller.dart';

class VoiceBubble extends StatefulWidget {
  final Message message;
  const VoiceBubble({super.key, required this.message});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  // Fixed random-looking bar heights generated once
  static final List<double> _barHeights = _generateBars();

  static List<double> _generateBars() {
    final rng = math.Random(42);
    return List.generate(15, (_) => 0.3 + rng.nextDouble() * 0.7);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
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
    final isUser = widget.message.senderType == SenderType.user;

    return GestureDetector(
      onTap: _togglePlay,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isUser ? AuraColors.userBubbleGradient : null,
          color: isUser ? null : AuraColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 24 : 0),
            topRight: Radius.circular(isUser ? 0 : 24),
            bottomLeft: const Radius.circular(24),
            bottomRight: const Radius.circular(24),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play / pause button circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUser
                    ? Colors.white
                    : AuraColors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: isUser ? AuraColors.primary : AuraColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            // Waveform bars
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = 3.0;
                  final barSpacing = 2.0; // horizontal padding * 2
                  final maxBars = ((constraints.maxWidth) / (barWidth + barSpacing)).floor().clamp(1, 15);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(maxBars, (i) {
                      final h = _barHeights[i] * 28;
                      final color = isUser
                          ? Colors.white.withValues(alpha: _isPlaying ? 0.9 : 0.5)
                          : AuraColors.primary.withValues(alpha: _isPlaying ? 0.6 : 0.35);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: _isPlaying ? 300 + i * 40 : 200),
                          width: 3,
                          height: _isPlaying ? h : h * 0.5,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Duration
            Text(
              '0:00', // TODO: 等后端 Message 增加 mediaDuration 字段后替换
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.8)
                    : AuraColors.onSurfaceVariant,
              ),
            ),
            // State indicator
            if (widget.message.isSending) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ] else if (widget.message.isFailed) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final c = Get.find<ChatController>();
                  c.retryVoiceMessage(widget.message);
                },
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
