import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.teal,
      surface: Colors.white,
      surfaceContainerHighest: Colors.grey[200],
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      ThemeData.light().textTheme.copyWith(
        bodyLarge: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
        bodyMedium: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.teal,
      surface: Color(0xFF1E1E1E),
      surfaceContainerHighest: Color(0xFF2E2E2E),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme.copyWith(
        bodyLarge: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[400]),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
  );
}