import 'package:flutter/material.dart';

class AppTheme {
  // Primary brand colors
  static const Color primaryRed = Color(0xFFD32F2F); // ClubIgnite red
  static const Color darkBlack = Color(0xFF121212);  // Dark theme bg
  static const Color lightWhite = Colors.white;

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightWhite,
    primaryColor: primaryRed,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: lightWhite,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: lightWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
      titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: lightWhite,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      labelStyle: const TextStyle(color: Colors.black87),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBlack,
    primaryColor: primaryRed,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: lightWhite,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: lightWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightWhite),
      bodyMedium: TextStyle(color: Colors.white70),
      titleMedium: TextStyle(color: lightWhite, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: lightWhite,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[850],
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
