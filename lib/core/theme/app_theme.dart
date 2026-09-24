import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF0EA5E9); // Electric Cyan/Blue
  static const accentColor = Color(0xFF10B981); // Emerald Green
  static const darkBg = Color(0xFF0F172A); // Deep Slate Dark
  static const cardBg = Color(0xFF1E293B); // Card Slate
  static const surfaceColor = Color(0xFF334155); // Surface border/divider

  static const TextStyle rabarStyle = TextStyle(fontFamily: 'Rabar');
  static const TextStyle nrtBoldStyle = TextStyle(
    fontFamily: 'NRT',
    fontWeight: FontWeight.w700,
  );

  static ThemeData get darkTheme {
    const rabarBase = TextStyle(fontFamily: 'Rabar', color: Colors.white);
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardBg,
      ),
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: rabarBase.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceColor, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: rabarBase.copyWith(color: Colors.white70),
        hintStyle: rabarBase.copyWith(color: Colors.white38),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: rabarBase.copyWith(fontSize: 57),
        displayMedium: rabarBase.copyWith(fontSize: 45),
        displaySmall: rabarBase.copyWith(fontSize: 36),
        headlineLarge: rabarBase.copyWith(fontSize: 32),
        headlineMedium: rabarBase.copyWith(fontSize: 28),
        headlineSmall: rabarBase.copyWith(fontSize: 24),
        titleLarge: rabarBase.copyWith(fontSize: 22),
        titleMedium: rabarBase.copyWith(fontSize: 16),
        titleSmall: rabarBase.copyWith(fontSize: 14),
        bodyLarge: rabarBase.copyWith(fontSize: 16),
        bodyMedium: rabarBase.copyWith(fontSize: 14),
        bodySmall: rabarBase.copyWith(fontSize: 12),
        labelLarge: rabarBase.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: rabarBase.copyWith(fontSize: 12),
        labelSmall: rabarBase.copyWith(fontSize: 11),
      ),
    );
  }
}
