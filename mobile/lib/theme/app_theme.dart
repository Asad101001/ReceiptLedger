import 'package:flutter/material.dart';

/// ReceiptLedger Design System & Theme Tokens
/// Strictly adheres to:
/// - Rule #1: ZERO GRADIENTS (solid colors, crisp 1px borders)
/// - Rule #2: ZERO LIQUID GLASS / GLASSMORPHISM (solid surfaces, crisp outlines)
class AppTheme {
  // Brand Header & Accents
  static const Color headerBlue = Color(0xFF749DF8); // Calm periwinkle blue from mockups
  static const Color headerBlueDark = Color(0xFF5E8AF3);
  static const Color navyBrand = Color(0xFF0C1E4A); // Deep midnight navy
  static const Color navyBrandLight = Color(0xFF162A86);
  static const Color navyBrandSurface = Color(0xFF132247);
  static const Color bluePillActive = Color(0xFF2563EB);

  // Light Theme Surfaces & Text
  static const Color canvasLight = Color(0xFFF7F9FC); // Off-white modern canvas
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Dark Theme Surfaces & Text
  static const Color canvasDark = Color(0xFF0A0F1D);
  static const Color cardDark = Color(0xFF131B2E);
  static const Color cardDarkElevated = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF24324D);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Status & Verification Indicators
  static const Color greenVerified = Color(0xFF10B981);
  static const Color greenVerifiedBg = Color(0xFFE8F7F0);
  static const Color greenVerifiedBgDark = Color(0xFF064E3B);
  
  static const Color badgeRed = Color(0xFFEF4444);
  static const Color badgeRedBg = Color(0xFFFEE2E2);

  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color amberWarningBg = Color(0xFFFEF3C7);
  static const Color amberWarningBgDark = Color(0xFF78350F);

  static const Color blueInfo = Color(0xFF3B82F6);
  static const Color blueInfoBg = Color(0xFFEFF6FF);

  // Profile Avatar Dark Green from SETTINGS.png
  static const Color avatarGreen = Color(0xFF194D33);
  static const Color avatarBorder = Color(0xFF10B981);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: headerBlue,
        primary: navyBrand,
        surface: cardWhite,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: headerBlue,
        primary: const Color(0xFF60A5FA),
        surface: cardDark,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
    );
  }
}

typedef AppColors = AppTheme;

