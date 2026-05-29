import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color gold = Color(0xFFD4A017);
  static const Color goldBright = Color(0xFFE8C14A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color border = Color(0xFF2A2A2A);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldBright,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Manrope',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'BigShouldersDisplay',
          fontWeight: FontWeight.w900,
          color: AppColors.gold,
          letterSpacing: 2,
        ),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
