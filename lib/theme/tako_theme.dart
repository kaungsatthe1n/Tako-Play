import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Main app theme, called [TakoTheme], is defined here.
class TakoTheme {
  static TextTheme darkTextTheme = TextTheme(
    bodyLarge: TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.normal,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleSmall: TextStyle(
      fontSize: 17.0,
      color: Colors.white,
    ),
    displayLarge: TextStyle(
      fontSize: 31.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    displaySmall: TextStyle(
      fontSize: 19.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    headlineMedium: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    headlineSmall: TextStyle(
      fontSize: 19.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    titleLarge: TextStyle(
      fontSize: 19.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: tkDarkBlue,
      scaffoldBackgroundColor: tkDarkerBlue,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.white,
        secondary: Colors.white38,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        onBackground: Colors.white,
        surface: Colors.grey,
        onSurface: Colors.white,
      ),
      hintColor: tkGradientBlue,
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.white,
        backgroundColor: tkDarkBlue,
        centerTitle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        backgroundColor: tkDarkBlue,
      ),
    );
  }
}
