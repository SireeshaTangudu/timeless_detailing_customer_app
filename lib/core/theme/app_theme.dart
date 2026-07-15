import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Palette toggle
  static bool isDark = true;

  static Color get background => isDark ? const Color(0xFF0C0C0E) : const Color(0xFFF9F9FB);
  static Color get surface => isDark ? const Color(0xFF16161A) : const Color(0xFFFFFFFF);
  static Color get surfaceLight => isDark ? const Color(0xFF222228) : const Color(0xFFF4F4F6);
  static const Color primary = Color(0xFFD4AF37); // Classic Gold
  static const Color primaryLight = Color(0xFFF3E5AB); // Soft Gold
  static const Color primaryDark = Color(0xFF997A15); // Darker Gold
  static Color get accent => isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);
  static Color get textPrimary => isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E);
  static Color get textSecondary => isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6E6E73);
  static Color get textMuted => isDark ? const Color(0xFF616161) : const Color(0xFFAEAEB2);
  static Color get divider => isDark ? const Color(0xFF2C2C35) : const Color(0xFFE5E5EA);
  static Color get cardBorder => isDark ? const Color(0xFF32323D) : const Color(0xFFE5E5EA);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // Gradient definitions
  static List<Color> get goldGradientColors => [primaryDark, primary, primaryLight];

  static LinearGradient get goldGradient => LinearGradient(
    colors: goldGradientColors,
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static LinearGradient get darkCardGradient => LinearGradient(
    colors: [surface, isDark ? const Color(0xFF1E1E24) : const Color(0xFFF0F0F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C0C0E),
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        surface: Color(0xFF16161A),
        error: error,
        onPrimary: Color(0xFF0C0C0E),
        onSecondary: Color(0xFF0C0C0E),
        onSurface: Color(0xFFF5F5F7),
      ),
      dividerColor: const Color(0xFF2C2C35),
      cardTheme: CardThemeData(
        color: const Color(0xFF16161A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF32323D), width: 1),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF5F5F7),
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF5F5F7),
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF5F5F7),
          letterSpacing: 0.1,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF5F5F7),
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFF5F5F7),
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFF5F5F7),
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF9E9E9E),
          height: 1.4,
        ),
        bodySmall: GoogleFonts.montserrat(
          fontSize: 12,
          color: const Color(0xFF616161),
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0C0C0E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF5F5F7),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF5F5F7)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16161A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.montserrat(color: const Color(0xFF616161), fontSize: 14),
        labelStyle: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF32323D), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF0C0C0E),
          backgroundColor: primary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9F9FB),
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: Colors.white,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1C1C1E),
      ),
      dividerColor: const Color(0xFFE5E5EA),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1C1E),
          letterSpacing: 0.1,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1C1E),
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1C1C1E),
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF1C1C1E),
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF6E6E73),
          height: 1.4,
        ),
        bodySmall: GoogleFonts.montserrat(
          fontSize: 12,
          color: const Color(0xFFAEAEB2),
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.montserrat(color: const Color(0xFFAEAEB2), fontSize: 14),
        labelStyle: GoogleFonts.montserrat(color: const Color(0xFF6E6E73), fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
