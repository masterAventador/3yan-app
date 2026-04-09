import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

/// UI shell for video messages — no actual playback, just a preview placeholder.
class VideoBubble extends StatelessWidget {
  final bool isUser;
  const VideoBubble({super.key, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isUser ? 32 : 0),
        topRight: Radius.circular(isUser ? 0 : 32),
        bottomLeft: const Radius.circular(32),
        bottomRight: const Radius.circular(32),
      ),
      child: SizedBox(
        width: 220,
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder background
            Container(color: AuraColors.surfaceContainerHigh),

            // Center frosted glass play button
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom progress bar
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Progress (33%)
                  FractionallySizedBox(
                    widthFactor: 0.33,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AuraColors.primaryFixed,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AuraColors.primaryFixed.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
