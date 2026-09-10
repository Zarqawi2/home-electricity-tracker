import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const lightPrimary = AppColors.lightPrimary;
    const lightBackground = AppColors.lightBackground;
    const lightSurface = AppColors.lightSurface;
    const lightSurface2 = AppColors.lightSurface2;
    const lightBorder = AppColors.lightBorder;
    const lightTextPrimary = AppColors.lightTextPrimary;
    const lightTextSecondary = AppColors.lightTextSecondary;
    const lightTextDisabled = AppColors.lightTextDisabled;
    const lightSecondary = AppColors.lightSecondary;
    const lightNegative = AppColors.lightNegative;

    return ThemeData(
      useMaterial3: false,
      fontFamily: 'Rabar',
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightBorder,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: lightPrimary,
            brightness: Brightness.light,
          ).copyWith(
            surface: lightSurface,
            secondary: lightSecondary,
            primary: lightPrimary,
            onPrimary: Colors.white,
            onSurface: lightTextPrimary,
            error: lightNegative,
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        modalBackgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightSurface,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(color: lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightTextPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(lightTextPrimary),
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface2,
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextDisabled),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : lightTextDisabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? lightPrimary
              : lightBorder,
        ),
      ),
      iconTheme: const IconThemeData(color: lightTextPrimary),
      primaryIconTheme: const IconThemeData(color: lightTextPrimary),
      disabledColor: lightTextDisabled,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurface,
        contentTextStyle: const TextStyle(color: lightTextPrimary),
        actionTextColor: lightTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: lightPrimary,
        selectionColor: Color(0x552E86FF),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: lightBorder),
        ),
      ),
      splashColor: AppColors.lightPrimarySoft,
      highlightColor: Colors.transparent,
      hoverColor: lightSurface2,
      focusColor: AppColors.lightPrimarySoft,
      visualDensity: VisualDensity.standard,
    );
  }
}
