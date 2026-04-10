import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

class HoldToSpeakButton extends StatelessWidget {
  final bool isPressed;
  final void Function(Offset globalPosition) onPressStart;
  final void Function(Offset globalPosition) onPressMove;
  final VoidCallback onPressEnd;
  final VoidCallback onPressCancel;

  const HoldToSpeakButton({
    super.key,
    required this.isPressed,
    required this.onPressStart,
    required this.onPressMove,
    required this.onPressEnd,
    required this.onPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) => onPressStart(details.globalPosition),
      onLongPressMoveUpdate: (details) => onPressMove(details.globalPosition),
      onLongPressEnd: (_) => onPressEnd(),
      onLongPressCancel: onPressCancel,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isPressed
              ? AuraColors.primaryFixed.withValues(alpha: 0.3)
              : AuraColors.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(9999),
        ),
        alignment: Alignment.center,
        child: Text(
          isPressed ? '正在录音...' : '按住说话',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isPressed
                ? AuraColors.primary
                : AuraColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
