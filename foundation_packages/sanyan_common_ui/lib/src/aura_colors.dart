import 'package:flutter/material.dart';

class AuraColors {
  // ── Ethereal Editorial palette ──────────────────────────────────────────

  // Primary — deep teal
  static const Color primary = Color(0xFF006B64);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFF73F1E4); // mint
  static const Color onPrimaryFixed = Color(0xFF00201E);

  // Secondary — ocean blue
  static const Color secondary = Color(0xFF006595);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFFCBE6FF);
  static const Color secondaryFixedDim = Color(0xFFAED9FF); // azure

  // Surface
  static const Color surface = Color(0xFFE2FFFF); // light mint bg
  static const Color onSurface = Color(0xFF00393A); // dark teal text
  static const Color onSurfaceVariant = Color(0xFF2A6869); // secondary text
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // cards
  static const Color surfaceContainerLow = Color(0xFFD5F6F6);
  static const Color surfaceContainer = Color(0xFFC5EDED);
  static const Color surfaceContainerHigh = Color(0xFFBCE8E8);
  static const Color surfaceContainerHighest = Color(0xFFB0EEEE); // input bg

  // Outline
  static const Color outline = Color(0xFF4C8E8F);
  static const Color outlineVariant = Color(0xFF80BCBD); // ghost borders

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Gradients ────────────────────────────────────────────────────────────

  /// Mint → Azure: used on buttons, send icon, active nav tab
  static const LinearGradient mintAzureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryFixed, secondaryFixedDim],
  );

  /// Deep teal → ocean blue: used on user chat bubbles
  static const LinearGradient userBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Glass panel constants ─────────────────────────────────────────────────

  static const double glassBlur = 24.0;
  static const Color glassColor = Color(0x66FFFFFF); // white / 40%
  static const Color glassBorder = Color(0x33FFFFFF); // white / 20%
  static const Color glassShadow = Color(0x1400393A); // #00393A / 8%

}
