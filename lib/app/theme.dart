import 'package:flutter/material.dart';

class NoriGoColors {
  const NoriGoColors._();

  static const ink = Color(0xFF183044);
  static const softInk = Color(0xFF4D667A);
  static const purple = Color(0xFF6A00FF);
  static const lime = Color(0xFFCCFF00);
  static const blue = Color(0xFF007BFF);
  static const sea = Color(0xFF157A86);
  static const mint = Color(0xFFDAF1EE);
  static const coral = Color(0xFFE76F51);
  static const gold = Color(0xFFE9B44C);
  static const sky = Color(0xFFEAF6FB);
  static const paper = Color(0xFFF8FAF9);
  static const line = Color(0xFFDDE7E4);
  static const success = Color(0xFF2D9C69);
  static const warning = Color(0xFFE39A22);
  static const danger = Color(0xFFD8524A);
}

class NoriGoTheme {
  const NoriGoTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NoriGoColors.sea,
      primary: NoriGoColors.sea,
      secondary: NoriGoColors.coral,
      tertiary: NoriGoColors.gold,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NoriGoColors.paper,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: NoriGoColors.paper,
        foregroundColor: NoriGoColors.ink,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: NoriGoColors.sea,
        unselectedItemColor: NoriGoColors.softInk,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: NoriGoColors.softInk),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NoriGoColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NoriGoColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NoriGoColors.sea, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: NoriGoColors.mint,
        disabledColor: NoriGoColors.line,
        labelStyle: const TextStyle(
          color: NoriGoColors.ink,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: NoriGoColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: NoriGoColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 30,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          color: NoriGoColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: NoriGoColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: NoriGoColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: NoriGoColors.ink,
          fontSize: 16,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: NoriGoColors.softInk,
          fontSize: 14,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: NoriGoColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
