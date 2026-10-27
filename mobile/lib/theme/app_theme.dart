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
  static const Color errorRed = Color(0xFFD9534F);
  static const Color badgeRedBg = Color(0xFFFDE8E8);
  static const Color amberWarning = Color(0xFFD97706);
  static const Color amberWarningBg = Color(0xFFFEF3C7);
  static const Color avatarGreen = Color(0xFF1E3A2B);

  // Harsh Minimalist Black & White Dark Palette (Brutalist Monochrome)
  static const Color canvasDark = Color(0xFF000000); // Pure pitch black
  static const Color cardDark = Color(0xFF0C0C0C); // Stark jet black surface
  static const Color cardDarkElevated = Color(0xFF171717); // Crisp elevated black
  static const Color borderDark = Color(0xFF262626); // High-contrast stark border
  static const Color borderDarkCrisp = Color(0xFF404040);
  static const Color textLight = Color(0xFFFFFFFF); // Pure stark white
  static const Color textMutedDark = Color(0xFFA3A3A3); // Crisp neutral monochrome gray

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

  // Plain Harsh Minimalist Black & White Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvasDark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFFD4D4D8),
        surface: cardDark,
        error: Color(0xFFFF453A),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderDarkCrisp, width: 1.2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: borderDark, width: 1.2),
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

/// Style definition for a financial category badge, chart accent, and card theme
class CategoryStyle {
  final String label;
  final Color primary;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color borderLight;
  final Color borderDark;
  final IconData icon;

  const CategoryStyle({
    required this.label,
    required this.primary,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.borderLight,
    required this.borderDark,
    required this.icon,
  });

  Color backgroundColor(bool isDark) => isDark ? backgroundDark : backgroundLight;
  Color borderColor(bool isDark) => isDark ? borderDark : borderLight;
}

/// Curated, executive financial category palette
/// Cohesive with forest green and linen canvas; tasteful, elegant, and non-garish.
class CategoryTheme {
  static const CategoryStyle groceries = CategoryStyle(
    label: 'Groceries',
    primary: Color(0xFF2E7D5B), // Fresh leaf emerald
    backgroundLight: Color(0xFFEAF5EE),
    backgroundDark: Color(0xFF142E20),
    borderLight: Color(0xFFC7E6D3),
    borderDark: Color(0xFF204832),
    icon: Icons.local_grocery_store_outlined,
  );

  static const CategoryStyle bakery = CategoryStyle(
    label: 'Bakeries',
    primary: Color(0xFFC26E00), // Warm toasted caramel
    backgroundLight: Color(0xFFFEF4E6),
    backgroundDark: Color(0xFF2B1C0B),
    borderLight: Color(0xFFFBDDB8),
    borderDark: Color(0xFF452E13),
    icon: Icons.bakery_dining_outlined,
  );

  static const CategoryStyle fuel = CategoryStyle(
    label: 'Fuel & Auto',
    primary: Color(0xFFD97706), // Petroleum warm amber
    backgroundLight: Color(0xFFFEF8EC),
    backgroundDark: Color(0xFF2B1F0A),
    borderLight: Color(0xFFFDE68A),
    borderDark: Color(0xFF453210),
    icon: Icons.local_gas_station_outlined,
  );

  static const CategoryStyle healthcare = CategoryStyle(
    label: 'Healthcare',
    primary: Color(0xFF0F766E), // Clinical calming teal
    backgroundLight: Color(0xFFE8F7F5),
    backgroundDark: Color(0xFF0E2724),
    borderLight: Color(0xFFBCE7E3),
    borderDark: Color(0xFF163E3A),
    icon: Icons.local_pharmacy_outlined,
  );

  static const CategoryStyle utilities = CategoryStyle(
    label: 'Utilities',
    primary: Color(0xFF4338CA), // Electric cobalt violet
    backgroundLight: Color(0xFFEEF2FF),
    backgroundDark: Color(0xFF161536),
    borderLight: Color(0xFFC7D2FE),
    borderDark: Color(0xFF232254),
    icon: Icons.bolt_outlined,
  );

  static const CategoryStyle household = CategoryStyle(
    label: 'Household',
    primary: Color(0xFF7C3AED), // Muted royal lavender
    backgroundLight: Color(0xFFF5F3FF),
    backgroundDark: Color(0xFF221338),
    borderLight: Color(0xFFDDD6FE),
    borderDark: Color(0xFF341E55),
    icon: Icons.home_outlined,
  );

  static const CategoryStyle personalCare = CategoryStyle(
    label: 'Personal Care',
    primary: Color(0xFFBE185D), // Subtle rosewood berry
    backgroundLight: Color(0xFFFDF2F8),
    backgroundDark: Color(0xFF2E0E1B),
    borderLight: Color(0xFFFBCFE8),
    borderDark: Color(0xFF471629),
    icon: Icons.spa_outlined,
  );

  static const CategoryStyle dining = CategoryStyle(
    label: 'Dining & Cafe',
    primary: Color(0xFFB45309), // Warm terracotta
    backgroundLight: Color(0xFFFFF7ED),
    backgroundDark: Color(0xFF2B1709),
    borderLight: Color(0xFFFED7AA),
    borderDark: Color(0xFF45260F),
    icon: Icons.restaurant_outlined,
  );

  static const CategoryStyle miscellaneous = CategoryStyle(
    label: 'Miscellaneous',
    primary: Color(0xFF475569), // Muted slate charcoal
    backgroundLight: Color(0xFFF1F5F9),
    backgroundDark: Color(0xFF1E293B),
    borderLight: Color(0xFFCBD5E1),
    borderDark: Color(0xFF334155),
    icon: Icons.receipt_long_outlined,
  );

  /// Resolves matching CategoryStyle from any raw category string or label
  static CategoryStyle getStyle(String? categoryName) {
    if (categoryName == null || categoryName.trim().isEmpty) return miscellaneous;
    final cat = categoryName.toLowerCase().trim();

    if (cat.contains('groc') || cat.contains('food') || cat.contains('super')) {
      return groceries;
    }
    if (cat.contains('bak') || cat.contains('sweet') || cat.contains('confec')) {
      return bakery;
    }
    if (cat.contains('fuel') || cat.contains('gas') || cat.contains('petrol') || cat.contains('transp')) {
      return fuel;
    }
    if (cat.contains('pharm') || cat.contains('health') || cat.contains('med') || (cat.contains('care') && cat.contains('health'))) {
      return healthcare;
    }
    if (cat.contains('util') || cat.contains('bill') || cat.contains('elect') || cat.contains('power') || cat.contains('water') || cat.contains('gas bill')) {
      return utilities;
    }
    if (cat.contains('house') || cat.contains('clean') || cat.contains('home')) {
      return household;
    }
    if (cat.contains('person') || cat.contains('cosmetic') || cat.contains('beauty') || cat.contains('care')) {
      return personalCare;
    }
    if (cat.contains('din') || cat.contains('rest') || cat.contains('cafe') || cat.contains('coffee')) {
      return dining;
    }
    return miscellaneous;
  }
}

/// Compatibility alias
typedef AppColors = AppTheme;
