import 'package:flutter/material.dart';

abstract final class AppColors {
  static const green = Color(0xFFB94E32);
  static const greenDark = Color(0xFF7A2E22);
  static const greenSoft = Color(0xFFFBE6DC);
  static const background = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFFCF8);
  static const orange = Color(0xFFE89B3C);
  static const orangeSoft = Color(0xFFFFE6C5);
  static const success = Color(0xFF2D7D5A);
  static const ink = Color(0xFF2A1D19);
  static const muted = Color(0xFF74645E);
  static const border = Color(0xFFEAD8CF);
  static const warning = Color(0xFFC47A12);
  static const danger = Color(0xFFB42318);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.greenDark.withValues(alpha: .14),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.green,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 70,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.greenSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
