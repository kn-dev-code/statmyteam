import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF070B14);
  static const surface = Color(0xFF121826);
  static const surfaceHigh = Color(0xFF1A2333);
  static const border = Color(0xFF2A3548);
  static const muted = Color(0xFF8B97AB);
  static const text = Color(0xFFF4F7FB);
  static const accent = Color(0xFF2EE59D);
  static const gold = Color(0xFFF5C542);
  static const danger = Color(0xFFFF5C7A);
  static const pending = Color(0xFF6EA8FF);
}

class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: Color(0xFF042016),
      secondary: AppColors.gold,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.border,
    );
  }
}
