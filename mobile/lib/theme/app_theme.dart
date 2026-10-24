import 'package:flutter/material.dart';

/// ReceiptLedger Design System & Theme Tokens
/// Modern Warm Financial Ledger Aesthetics:
/// - Soft linen / cream background
/// - Deep forest / spruce green primary accents
/// - Calming sage secondary tones and pill chips
class AppTheme {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static void toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  // Brand Forest & Sage Palette (Light Mode)
  static const Color forestPrimary = Color(0xFF1E3A2B); // Deep luxurious pine green
  static const Color forestDark = Color(0xFF14271D);
  static const Color forestLight = Color(0xFF2C533E);
  static const Color sageAccent = Color(0xFF6B8775); // Calming sage accent
  static const Color sageLight = Color(0xFFEAF0EB); // Soft sage background for chips
  static const Color sageMuted = Color(0xFFD6E2D8);

  // Backward-compatibility aliases for legacy navy references (maps to forest luxury palette)
  static const Color navyBrand = forestPrimary;
  static const Color navyLight = sageAccent;
  static const Color borderNavy = borderLight;
  static const Color headerBlue = forestPrimary;
  static const Color headerBlueDark = forestDark;

  // Canvas & Surfaces
  static const Color canvasLight = Color(0xFFF8F9F5); // Warm organic linen/cream
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardSubtle = Color(0xFFF3F5F0);
  static const Color borderLight = Color(0xFFE8ECE7);
  static const Color borderSubtle = Color(0xFFDFE4DE);

  // Typography Palette
  static const Color textDark = Color(0xFF141E18); // Deep warm charcoal
  static const Color textMuted = Color(0xFF5A6B60); // Muted slate green
  static const Color textMutedLight = Color(0xFF8A9E91);

  // Status & Badges
  static const Color greenVerified = Color(0xFF2E7D5B);
  static const Color greenVerifiedBg = Color(0xFFE7F3EC);
  static const Color badgeRed = Color(0xFFD9534F); // Muted terracotta red
  static const Color badgeRedBg = Color(0xFFFDE8E8);
  static const Color amberWarning = Color(0xFFD97706);
  static const Color amberWarningBg = Color(0xFFFEF3C7);
  static const Color avatarGreen = Color(0xFF1E3A2B);

  // Dark Theme Palette
  static const Color canvasDark = Color(0xFF0F1713); // Deep obsidian forest
  static const Color cardDark = Color(0xFF18241D); // Dark pine surface
  static const Color cardDarkElevated = Color(0xFF213027);
  static const Color borderDark = Color(0xFF293B31);
  static const Color textLight = Color(0xFFF3F6F4);
  static const Color textMutedDark = Color(0xFF8FA597);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasLight,
      colorScheme: const ColorScheme.light(
        primary: forestPrimary,
        secondary: sageAccent,
        surface: cardWhite,
        error: badgeRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: forestPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvasDark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF86AB93),
        secondary: Color(0xFF6B8775),
        surface: cardDark,
        error: badgeRed,
        onPrimary: forestDark,
        onSecondary: Colors.white,
        onSurface: textLight,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Compatibility alias
typedef AppColors = AppTheme;
