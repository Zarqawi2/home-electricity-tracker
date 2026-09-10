import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light-only neutral palette.
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF8FAFC);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextDisabled = Color(0xFF94A3B8);
  static const lightPrimary = Color(0xFF2563EB);
  static const lightPrimaryPressed = Color(0xFF1D4ED8);
  static const lightPrimarySoft = lightSurface2;
  static const lightSecondary = lightPrimary;
  static const lightSecondarySoft = lightPrimarySoft;

  // Semantic colors are reserved for status and validation feedback.
  static const lightPositive = Color(0xFF16A34A);
  static const lightWarning = Color(0xFFD97706);
  static const lightNegative = Color(0xFFDC2626);
  static const lightInfo = lightPrimary;
  static const lightChartLine1 = lightTextPrimary;
  static const lightChartLine2 = lightTextSecondary;
  static const lightChartHighlight = lightPrimary;
  static const lightPrimaryGlow = Color(0xFF000000);

  // Backward-compatible aliases use the same light palette.
  static const background = lightBackground;
  static const surface = lightSurface;
  static const surface2 = lightSurface2;
  static const cardBorder = lightBorder;
  static const textPrimary = lightTextPrimary;
  static const textSecondary = lightTextSecondary;
  static const textDisabled = lightTextDisabled;
  static const primary = lightPrimary;
  static const primaryPressed = lightPrimaryPressed;
  static const primarySoft = lightPrimarySoft;
  static const positive = lightPositive;
  static const warning = lightWarning;
  static const negative = lightNegative;
  static const info = lightInfo;
  static const chartLine1 = lightChartLine1;
  static const chartLine2 = lightChartLine2;
  static const chartHighlight = lightChartHighlight;
  static const accentYellow = warning;
  static const accentBlue = primary;
  static const muted = lightSurface2;
  static const primaryGlow = lightPrimaryGlow;

  static Color backgroundFor(BuildContext _) => lightBackground;
  static Color surfaceFor(BuildContext _) => lightSurface;
  static Color surface2For(BuildContext _) => lightSurface2;
  static Color borderFor(BuildContext _) => lightBorder;
  static Color textPrimaryFor(BuildContext _) => lightTextPrimary;
  static Color textSecondaryFor(BuildContext _) => lightTextSecondary;
  static Color textDisabledFor(BuildContext _) => lightTextDisabled;
  static Color primaryFor(BuildContext _) => lightPrimary;
  static Color primaryPressedFor(BuildContext _) => lightPrimaryPressed;
  static Color primarySoftFor(BuildContext _) => lightPrimarySoft;
  static Color secondaryFor(BuildContext _) => lightSecondary;
  static Color secondarySoftFor(BuildContext _) => lightSecondarySoft;
  static Color positiveFor(BuildContext _) => lightPositive;
  static Color warningFor(BuildContext _) => lightWarning;
  static Color negativeFor(BuildContext _) => lightNegative;
  static Color infoFor(BuildContext _) => lightInfo;
  static Color chartLine1For(BuildContext _) => lightChartLine1;
  static Color chartLine2For(BuildContext _) => lightChartLine2;
  static Color chartHighlightFor(BuildContext _) => lightChartHighlight;
  static Color primaryGlowFor(BuildContext _) => lightPrimaryGlow;
}
