import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../aura_colors.dart';

/// Gradient action button with optional trailing icon and loading state.
///
/// Usage:
/// ```dart
/// AuraButton(
///   label: '登录',
///   onPressed: c.login,
///   isLoading: c.isLoading.value,
/// )
/// ```
class AuraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const AuraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: AuraColors.mintAzureGradient,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: AuraColors.primaryFixed.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AuraColors.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, size: 18, color: AuraColors.onSurface),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
