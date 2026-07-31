import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

  // New Light Theme Colors (Variant Design)
  static const Color background = Color(0xFFF4F7FE); // Light gray-blue
  static const Color primaryBlue = Color(0xFF0052FF); // Vibrant primary blue
  static const Color primaryBlueLight = Color(0xFFE6EFFF); // Light blue for cards/highlights
  
  // Accents and Text
  static const Color textDark = Color(0xFF0A1128); // Deep Navy (near black)
  static const Color textMuted = Color(0xFF8F9BBA); // Soft grayish blue
  static const Color textMuted50 = Color(0x808F9BBA);
  static const Color textMuted10 = Color(0x1A8F9BBA);
  static const Color white = Colors.white;
  static const Color cardBackground = Colors.white;

  // Status colors
  static const Color success = Color(0xFF01B574);
  static const Color successLight = Color(0xFFE6F8F0);
  static const Color warning = Color(0xFFFFB547);
  static const Color warningLight = Color(0xFFFFF7E6);
  static const Color error = Color(0xFFEE5D50);

  // Legacy variables for compatibility temporarily (to be phased out during cleanup)
  static const Color voidBlack = textDark; 
  static const Color surfaceLight = white;
  static const Color peachBackground = background;
  static const Color blueVibrant = primaryBlue;
  static const Color limeLight = primaryBlueLight;
  static const Color bluePale = primaryBlueLight;
  static const Color greenDeep = primaryBlue;
  static const Color sageGreen = primaryBlue;
  static const Color sageGreenLight = primaryBlueLight;
  static const Color surfaceDark = Color(0xFF0A1128);
  static const Color orangeAccent = warning;
  static const Color purpleDeep = primaryBlue;

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: background,
        surface: white,
        onSurface: textDark,
        background: background,
      ),
      textTheme: _textTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: _textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: _textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: const Color(0x147090B0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: white,
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: primaryBlue),
    );
  }
}
