import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  static const Color voidBlack = Color(0xFF050505);
  static const Color blueVibrant = Color(0xFF4354FF);
  static const Color greenDeep = Color(0xFF02503A);
  static const Color limeLight = Color(0xFFA7F3D0);
  static const Color bluePale = Color(0xFF90CDF4);
  static const Color surfaceLight = Color(0xFF1A1A1A);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: blueVibrant,
        secondary: limeLight,
        surface: voidBlack,
        onSurface: Colors.white,
        background: voidBlack,
      ),
      textTheme: _textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: voidBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeLight,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: _textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: surfaceLight,
      ),
    );
  }
}
