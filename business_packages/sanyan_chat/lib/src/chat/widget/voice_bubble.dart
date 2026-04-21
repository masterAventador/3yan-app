import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../../api/models/message.dart';

/// 单例协调器：同时只允许一个 VoiceBubble 在播放，点新气泡先停当前的。
class _VoicePlaybackCoordinator {
  static _VoiceBubbleState? _current;

  static Future<void> register(_VoiceBubbleState bubble) async {
    if (_current != null && _current != bubble) {
      await _current!._stopInternal();
    }
    _current = bubble;
  }

  static void unregister(_VoiceBubbleState bubble) {
    if (_current == bubble) _current = null;
  }
}

class VoiceBubble extends StatefulWidget {
  final Message message;

  /// 外层传入的气泡最大宽度上限（60s 对应的满宽）。
  final double maxWidth;

  const VoiceBubble({super.key, required this.message, required this.maxWidth});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  // 波形参数
  static const int _maxSeconds = 60;
  static const int _minBars = 3;
  static const int _maxBars = 40;
  static const double _barSlot = 5.0; // bar 3px + padding 1*2

  // 气泡内部尺寸参数
  static const double _paddingH = 12.0;
  static const double _paddingV = 8.0;
  static const double _bubbleHeight = 40.0;
  static const double _waveTextGap = 8.0;
  static const double _durationTextWidth = 28.0; // "0:XX" Inter 11 约 22-25px

  // 40 根备选波形条高度（0.3~1.0 随机），所有气泡共享
  static final List<double> _barHeights = _generateBars(_maxBars);

  static List<double> _generateBars(int count) {
    final rng = math.Random(42);
    return List.generate(count, (_) => 0.3 + rng.nextDouble() * 0.7);
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
      _VoicePlaybackCoordinator.unregister(this);
    });
  }

  @override
  void dispose() {
    _VoicePlaybackCoordinator.unregister(this);
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _stopInternal();
      return;
    }

    // 播放源：优先 mediaUrl，刚发送上传未完成时兜底走 localFilePath
    final url = widget.message.mediaUrl;
    final local = widget.message.localFilePath;
    if (url == null && local == null) return;

    await _VoicePlaybackCoordinator.register(this);
    setState(() => _isPlaying = true);

    try {
      if (url != null) {
        await _player.play(UrlSource(url));
      } else {
        await _player.play(DeviceFileSource(local!));
      }
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
      _VoicePlaybackCoordinator.unregister(this);
    }
  }

  Future<void> _stopInternal() async {
    await _player.stop();
    if (mounted) setState(() => _isPlaying = false);
    _VoicePlaybackCoordinator.unregister(this);
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// 根据语音时长算出波形条数：duration/60 × 40，clamp 到 [minBars, maxBars]，
  /// 再进一步 clamp 不超过外层 maxWidth 允许的上限。
  int _computeBarCount() {
    final seconds = widget.message.duration ?? 0;
    int n = (seconds * _maxBars / _maxSeconds).round();
    if (n < _minBars) n = _minBars;
    if (n > _maxBars) n = _maxBars;

    final nonWaveWidth = _paddingH * 2 + _waveTextGap + _durationTextWidth;
    final maxBarsByWidth =
        ((widget.maxWidth - nonWaveWidth) / _barSlot).floor();
    if (n > maxBarsByWidth) n = maxBarsByWidth;
    if (n < _minBars) n = _minBars;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.senderType == SenderType.user;
    final n = _computeBarCount();

    // 气泡宽度直接由条数公式算出，不依赖内容的 intrinsic 尺寸，first frame 就是最终尺寸
    final bubbleW = _paddingH * 2 + n * _barSlot + _waveTextGap + _durationTextWidth;

    final bubble = SizedBox(
      width: bubbleW,
      height: _bubbleHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _paddingH,
          vertical: _paddingV,
        ),
        decoration: BoxDecoration(
          gradient: isUser ? AuraColors.userBubbleGradient : null,
          color: isUser ? null : AuraColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 12 : 4),
            topRight: Radius.circular(isUser ? 4 : 12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
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
            _Waveform(
              isUser: isUser,
              isPlaying: _isPlaying,
              bars: _barHeights.take(n).toList(),
            ),
            const SizedBox(width: _waveTextGap),
            Text(
              _formatDuration(widget.message.duration),
              style: TextStyle(
                fontFamily: AuraFonts.inter,
                fontSize: 11,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.85)
                    : AuraColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    // 播放态挂一个可发现的 key，供 E2E 测试探测。
    // sending / failed 状态指示由外层 MessageBubbleBase 统一处理。
    return GestureDetector(
      key: _isPlaying ? ValueKey('voice_playing_${widget.message.id}') : null,
      onTap: _togglePlay,
      child: bubble,
    );
  }
}

/// 波形条：播放时每根条按正弦相位连续上下跳动，静止时维持 50% 高度。
class _Waveform extends StatefulWidget {
  final bool isUser;
  final bool isPlaying;
  final List<double> bars;

  const _Waveform({
    required this.isUser,
    required this.isPlaying,
    required this.bars,
  });

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser
        ? Colors.white.withValues(alpha: widget.isPlaying ? 0.9 : 0.5)
        : AuraColors.primary.withValues(alpha: widget.isPlaying ? 0.6 : 0.35);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.bars.length, (i) {
            final base = widget.bars[i] * 24;
            double h;
            if (widget.isPlaying) {
              // 每根条有相位偏移，形成波浪式起伏；范围 [35%, 100%] × base
              final phase = i * 0.55;
              final t = _ctrl.value * 2 * math.pi + phase;
              final factor = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t));
              h = base * factor;
            } else {
              h = base * 0.5;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
