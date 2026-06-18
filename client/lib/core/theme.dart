import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

  // New Light Theme Colors
  static const Color peachBackground = Color(0xFFFFF0E5); // Soft peach
  static const Color sageGreen = Color(0xFF8A9A5B); // Sage green
  static const Color sageGreenLight = Color(0xFFE3EAD8); // Very light sage green for cards/highlights
  
  // Accents and Text
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMuted = Color(0xFF718096);
  static const Color textMuted50 = Color(0x80718096);
  static const Color textMuted10 = Color(0x1A718096);
  static const Color white = Colors.white;
  static const Color cardBackground = Colors.white;

  // Legacy variables for compatibility temporarily (to be phased out during cleanup)
  static const Color voidBlack = textDark; 
  static const Color surfaceLight = white;
  static const Color blueVibrant = sageGreen;
  static const Color limeLight = sageGreenLight;
  static const Color bluePale = sageGreenLight;

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: peachBackground,
      colorScheme: const ColorScheme.light(
        primary: sageGreen,
        secondary: peachBackground,
        surface: white,
        onSurface: textDark,
        background: peachBackground,
      ),
      textTheme: _textTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: sageGreen,
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
          backgroundColor: sageGreen,
          foregroundcolor: AppTheme.textDark,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: _textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sageGreenLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sageGreenLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sageGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: sageGreen.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: white,
      ),
      iconTheme: const IconThemeData(color: sageGreen),
    );
  }
}
