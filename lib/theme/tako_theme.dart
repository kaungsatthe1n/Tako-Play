import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

/// Shared visual language for the app's dark, cinematic interface.
class TakoTheme {
  static TextStyle _dmSans(double size, FontWeight weight) =>
      GoogleFonts.dmSans(
        color: Colors.white,
        fontSize: size,
        fontWeight: weight,
      );

  static final TextTheme darkTextTheme = TextTheme(
    bodyLarge: _dmSans(15, FontWeight.w500),
    bodyMedium: _dmSans(13, FontWeight.w500),
    titleMedium: _dmSans(15, FontWeight.w800),
    titleSmall: _dmSans(14, FontWeight.w700),
    displayLarge: _dmSans(34, FontWeight.w800),
    displayMedium: _dmSans(20, FontWeight.w800),
    displaySmall: _dmSans(18, FontWeight.w700),
    headlineMedium: _dmSans(24, FontWeight.w800),
    headlineSmall: _dmSans(20, FontWeight.w800),
    titleLarge: _dmSans(18, FontWeight.w800),
  );

  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: tkGradientBlue,
      onPrimary: Colors.white,
      secondary: tkCoral,
      onSecondary: Colors.white,
      error: tkCoral,
      onError: Colors.white,
      surface: tkDarkBlue,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      colorScheme: scheme,
      primaryColor: tkGradientBlue,
      scaffoldBackgroundColor: tkDarkerBlue,
      textTheme: darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12),
      chipTheme: ChipThemeData(
        backgroundColor: tkGrey,
        labelStyle: darkTextTheme.bodyMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: tkCoral,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tkDarkBlue,
        indicatorColor: tkGradientBlue.withValues(alpha: .25),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 23)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tkDarkBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
