import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Constants
  static const Color backgroundColor = Color(0xFF0C0F12);
  static const Color foregroundColor = Color(0xFFF1F3F5);

  static const Color cardColor = Color(0xFF151A1E);
  static const Color cardForegroundColor = Color(0xFFF1F3F5);

  static const Color primaryColor = Color(0xFF00B8D4);
  static const Color primaryForegroundColor = Color(0xFF080A0C);

  static const Color secondaryColor = Color(0xFF20262D);
  static const Color secondaryForegroundColor = Color(0xFFE2E6EA);

  static const Color mutedColor = Color(0xFF1E232B);
  static const Color mutedForegroundColor = Color(0xFF808E9D);

  static const Color accentColor = Color(0xFF33C6E3);
  static const Color destructiveColor = Color(0xFFF03A3A);

  static const Color borderColor = Color(0xFF282F38);
  static const Color inputColor = Color(0xFF282F38);
  static const Color ringColor = Color(0xFF00B8D4);

  // Gradient Constants
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF33C6E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0C0F12), Color(0xFF131920), Color(0xFF0C0F12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      offset: const Offset(0, 8),
      blurRadius: 32,
    ),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      cardColor: cardColor,
      dividerColor: borderColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: primaryForegroundColor,
        secondary: accentColor,
        surface: cardColor,
        onSurface: foregroundColor,
        error: destructiveColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: cardColor.withValues(alpha: 0.96),
        indicatorColor: primaryColor.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? primaryColor : mutedForegroundColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primaryColor : mutedForegroundColor,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: primaryForegroundColor,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bebasNeue(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: foregroundColor,
        ),
        displayMedium: GoogleFonts.bebasNeue(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: foregroundColor,
        ),
        displaySmall: GoogleFonts.bebasNeue(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: foregroundColor,
        ),
        headlineLarge: GoogleFonts.bebasNeue(
          fontSize: 32,
          letterSpacing: 0.5,
          color: foregroundColor,
        ),
        headlineMedium: GoogleFonts.bebasNeue(
          fontSize: 24,
          letterSpacing: 0.5,
          color: foregroundColor,
        ),
        headlineSmall: GoogleFonts.bebasNeue(
          fontSize: 20,
          letterSpacing: 0.5,
          color: foregroundColor,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: foregroundColor),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: secondaryForegroundColor,
        ),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: mutedForegroundColor),
        titleLarge: GoogleFonts.bebasNeue(
          fontSize: 22,
          letterSpacing: 0.5,
          color: foregroundColor,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foregroundColor,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ringColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructiveColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructiveColor, width: 2),
        ),
        labelStyle: TextStyle(color: mutedForegroundColor),
        hintStyle: TextStyle(
          color: mutedForegroundColor.withValues(alpha: 0.7),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: primaryForegroundColor,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
