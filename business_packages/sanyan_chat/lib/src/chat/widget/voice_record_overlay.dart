import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

class VoiceRecordOverlay extends StatefulWidget {
  final bool isCancelling;

  const VoiceRecordOverlay({super.key, required this.isCancelling});

  @override
  State<VoiceRecordOverlay> createState() => _VoiceRecordOverlayState();
}

class _VoiceRecordOverlayState extends State<VoiceRecordOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AuraColors.surfaceContainerHigh.withValues(alpha: 0.4),
                AuraColors.surface.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWaveform(),
                  _buildMicCircle(),
                  _buildHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(7, (i) {
          final delays = [0.1, 0.3, 0.5, 0.2, 0.4, 0.6, 0.1];
          final colors = [
            AuraColors.primary.withValues(alpha: 0.4),
            AuraColors.primary.withValues(alpha: 0.6),
            AuraColors.primary,
            AuraColors.secondary,
            AuraColors.primary,
            AuraColors.primary.withValues(alpha: 0.6),
            AuraColors.primary.withValues(alpha: 0.4),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _AnimatedBar(
              delay: delays[i],
              color: colors[i],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMicCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.isCancelling ? Colors.red : AuraColors.primary)
                    .withValues(alpha: 0.2 * _pulseController.value),
              ),
            );
          },
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCancelling ? Colors.red : null,
            gradient: widget.isCancelling
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AuraColors.primary, AuraColors.secondary],
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            widget.isCancelling ? Icons.close : Icons.mic,
            color: Colors.white,
            size: 60,
          ),
        ),
      ],
    );
  }

  Widget _buildHint() {
    return Column(
      children: [
        Text(
          widget.isCancelling
              ? 'Release to cancel'
              : 'Release to send, Swipe up to cancel',
          style: TextStyle(
            fontFamily: AuraFonts.manrope,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: widget.isCancelling ? Colors.red : AuraColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isCancelling ? '松开取消' : '松开发送，上滑取消',
          style: TextStyle(
            fontFamily: AuraFonts.inter,
            fontSize: 12,
            color: AuraColors.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final double delay;
  final Color color;
  const _AnimatedBar({required this.delay, required this.color});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3,
          height: 64 * _animation.value,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
