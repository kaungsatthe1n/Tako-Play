import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Main app theme, called [TakoTheme], is defined here.
class TakoTheme {
  static TextTheme darkTextTheme = TextTheme();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: tkDarkBlue,
      scaffoldBackgroundColor: tkDarkerBlue,
      colorScheme: ColorScheme.dark(
        primary: tkDarkBlue,
        onPrimary: Colors.white,
        secondary: Colors.green,
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
