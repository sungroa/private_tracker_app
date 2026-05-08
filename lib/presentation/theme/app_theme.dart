import 'package:flutter/material.dart';

class AppTheme {
  // --- Palette: Day Mode ---
  static const Color primaryColor = Color(0xFF6750A4); // Deep Indigo
  static const Color accentColor = Color(0xFFFFD8E4); // Soft Rose
  static const Color backgroundColor = Color(0xFFFFFBFE); // Creamy White
  static const Color surfaceColor = Color(0x66FFFFFF); // Glass Base

  // --- Palette: Night Mode ---
  static const Color primaryDarkColor = Color(0xFFD0BCFF); // Light Lavender
  static const Color accentDarkColor = Color(0xFF4F378B); // Deep Violet
  static const Color backgroundDarkColor = Color(0xFF1C1B1F); // Near Black
  static const Color surfaceDarkColor = Color(0x22FFFFFF); // Dark Glass Base

  // --- Shared Aesthetics ---
  static const String fontFamily = 'Outfit'; // Premium look

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        brightness: Brightness.light,
      ),
      fontFamily: fontFamily,
      scaffoldBackgroundColor: Colors.transparent, // Background handled by layer
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDarkColor,
        primary: primaryDarkColor,
        secondary: accentDarkColor,
        surface: backgroundDarkColor,
        brightness: Brightness.dark,
      ),
      fontFamily: fontFamily,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryDarkColor,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDarkColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
      ),
    );
  }

  // --- Premium Glassmorphism ---
  static BoxDecoration glassDecoration({bool isDark = false, double borderRadius = 28, Color? borderColor}) {
    return BoxDecoration(
      color: isDark ? surfaceDarkColor : surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4)),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }

  static BoxDecoration calendarSelectionDecoration({bool isDark = false}) {
    final primary = isDark ? primaryDarkColor : primaryColor;
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isDark ? primary.withValues(alpha: 0.2) : primary.withValues(alpha: 0.1),
      border: Border.all(
        color: primary.withValues(alpha: 0.5),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.4),
          blurRadius: 4,
          spreadRadius: -2,
          offset: const Offset(-2, -2),
        ),
      ],
      gradient: RadialGradient(
        colors: [
          primary.withValues(alpha: isDark ? 0.3 : 0.15),
          primary.withValues(alpha: isDark ? 0.1 : 0.05),
        ],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      ),
    );
  }

  /// Glassmorphic decoration for the "Return to Today" mini-FAB.
  ///
  /// Uses a semi-transparent primary tint with a subtle white border and
  /// a soft glow shadow — consistent with the app's glass design language.
  static BoxDecoration glassFabDecoration({bool isDark = false}) {
    final primary = isDark ? primaryDarkColor : primaryColor;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: isDark ? primary.withValues(alpha: 0.20) : primary.withValues(alpha: 0.12),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class PremiumGradients {
  static const List<Color> lightBackground = [
    Color(0xFFFFFBFE),
    Color(0xFFFFE0E9), // Gentle soft rose
  ];

  static const List<Color> darkBackground = [
    Color(0xFF1C1B1F),
    Color(0xFF2E1A47), // Deep purple night
  ];

  static const List<Color> accentGradient = [
    Color(0xFF6750A4),
    Color(0xFF9070D8),
  ];
}
