import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'aura_colors.dart';
import 'aura_fonts.dart';

class AuraTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AuraColors.surface,
      fontFamily: AuraFonts.manrope,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AuraColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // 背景是浅色（白 + 毛玻璃），状态栏文字/图标必须为深色
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android
          statusBarBrightness: Brightness.light, // iOS: light 背景 → dark 文字
        ),
        titleTextStyle: TextStyle(
          fontFamily: AuraFonts.manrope,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AuraColors.onSurface,
        ),
        iconTheme: const IconThemeData(
          color: AuraColors.primary,
          size: 28,
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) =>
            const Icon(Icons.chevron_left, size: 28),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AuraColors.primary,
        onPrimary: AuraColors.onPrimary,
        primaryContainer: AuraColors.primaryFixed,
        onPrimaryContainer: AuraColors.onPrimaryFixed,
        secondary: AuraColors.secondary,
        onSecondary: AuraColors.onSecondary,
        secondaryContainer: AuraColors.secondaryFixed,
        onSecondaryContainer: AuraColors.secondary,
        surface: AuraColors.surface,
        onSurface: AuraColors.onSurface,
        surfaceContainerLowest: AuraColors.surfaceContainerLowest,
        surfaceContainerLow: AuraColors.surfaceContainerLow,
        surfaceContainer: AuraColors.surfaceContainer,
        surfaceContainerHigh: AuraColors.surfaceContainerHigh,
        surfaceContainerHighest: AuraColors.surfaceContainerHighest,
        error: AuraColors.error,
        onError: AuraColors.onError,
        outline: AuraColors.outline,
        outlineVariant: AuraColors.outlineVariant,
      ),
    );
    return base;
  }
}
