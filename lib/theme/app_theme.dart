import 'package:flutter/material.dart';

/// پالت رنگی رسمی بازی کوماندوئل - نسخه لاکچری طلایی و مشکی
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF0B0B0B);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color gold = Color(0xFFD4AF37);
  static const Color brightGold = Color(0xFFFFD700);
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color neutralGray = Color(0xFF4A4A4A);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brightGold, gold],
  );

  static const RadialGradient goldGlow = RadialGradient(
    colors: [Color(0x66FFD700), Color(0x00FFD700)],
  );
}

class AppTheme {
  /// استاندارد اندازه کنترل‌های لمسی کوماندوئل.
  static const double minTouchTarget = 48.0;
  static const double secondaryButtonHeight = 52.0;
  static const double primaryButtonHeight = 56.0;
  static const double gameActionButtonSize = 48.0;
  static const double playerPillHeight = 52.0;
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.brightGold,
        surface: AppColors.charcoal,
        error: AppColors.error,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(80, minTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(80, minTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(80, minTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w900,
          color: AppColors.gold,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
    );
  }
}
