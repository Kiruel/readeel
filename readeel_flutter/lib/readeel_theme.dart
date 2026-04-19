import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadeelTheme {
  // "Antique Paper" Colors
  static const Color antiquePaperBackground = Color(0xFFFDFCF0);
  static const Color antiquePaperText = Color(0xFF1A1A1B);
  static const Color antiquePaperAccent = Color(0xFFC4A484); // Leather

  // "Nocturnal" Colors
  static const Color nocturnalBackground = Color(0xFF121212);
  static const Color nocturnalText = Color(0xFFE1E1E1);
  static const Color nocturnalAccent = Color(0xFF8D6E63);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        surface: antiquePaperBackground,
        primary: antiquePaperAccent,
        onSurface: antiquePaperText,
      ),
      scaffoldBackgroundColor: antiquePaperBackground,
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.merriweather(
          color: antiquePaperText,
          fontSize: 18,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.merriweather(
          color: antiquePaperText,
          fontSize: 16,
          height: 1.6,
        ),
        displayLarge: GoogleFonts.inter(
          color: antiquePaperText,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleMedium: GoogleFonts.inter(
          color: antiquePaperText.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        surface: nocturnalBackground,
        primary: nocturnalAccent,
        onSurface: nocturnalText,
      ),
      scaffoldBackgroundColor: nocturnalBackground,
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.merriweather(
          color: nocturnalText,
          fontSize: 18,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.merriweather(
          color: nocturnalText,
          fontSize: 16,
          height: 1.6,
        ),
        displayLarge: GoogleFonts.inter(
          color: nocturnalText,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleMedium: GoogleFonts.inter(
          color: nocturnalText.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }
}
