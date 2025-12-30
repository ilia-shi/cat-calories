import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      appBarTheme: AppBarTheme(
        toolbarTextStyle: TextStyle(fontSize: 16),
        titleTextStyle: TextStyle(fontSize: 16, color: Colors.black),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 16, color: Colors.black),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.white,
        secondary: Colors.cyan,
        surface: const Color(0xffffffff),
        onPrimary: const Color(0xff000000),
      ),
      disabledColor: Colors.grey,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Ubuntu',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.cyan,
        ),
      ),
    );
  }
}