import 'dart:ui';
import 'package:flutter/material.dart';
import '../aura_colors.dart';

/// Frosted glass container.
///
/// Usage:
/// ```dart
/// GlassPanel(
///   borderRadius: 24,
///   padding: const EdgeInsets.all(20),
///   child: ...,
/// )
/// ```
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuraColors.glassBlur,
          sigmaY: AuraColors.glassBlur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AuraColors.glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AuraColors.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AuraColors.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
