import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../aura_colors.dart';

/// Styled input field with optional label, left icon, and suffix widget.
///
/// Usage:
/// ```dart
/// AuraInput(
///   controller: myController,
///   label: 'PHONE',
///   hintText: '手机号',
///   leadingIcon: Icons.phone,
/// )
/// ```
class AuraInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? leadingIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const AuraInput({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.leadingIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AuraColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AuraColors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuraColors.outlineVariant.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                const SizedBox(width: 16),
                Icon(leadingIcon, size: 20, color: AuraColors.onSurfaceVariant),
                const SizedBox(width: 10),
              ] else
                const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AuraColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 15,
                      color: AuraColors.outlineVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null) ...[
                suffix!,
                const SizedBox(width: 12),
              ] else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}
