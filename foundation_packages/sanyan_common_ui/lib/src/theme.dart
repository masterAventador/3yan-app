import 'package:flutter/material.dart';

class AppColors {
  // Brand - 暖阳橘
  static const Color brandStart = Color(0xFFFFB347);
  static const Color brandEnd = Color(0xFFFF6B35);
  static const Color brandButton = Color(0xFFFF8040);
  static const Color accent = Color(0xFFF07020);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandStart, brandEnd],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [brandStart, brandButton],
  );

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF9B9B9B);
  static const Color textPlaceholder = Color(0xFFBCBCBC);

  // Surface
  static const Color background = Colors.white;
  static const Color inputFill = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFEBEBEB);
  static const Color border = Color(0xFFE0E0E0);

  // Chat
  static const Color aiBubble = Color(0xFFF5F5F5);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(
            color: AppColors.textPrimary,
            size: 28,
          ),
        ),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (context) => const Icon(Icons.chevron_left, size: 28),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandButton,
          surface: AppColors.background,
        ),
      );
}
