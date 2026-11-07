import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

/// Shared visual language for the app's dark, cinematic interface.
class TakoTheme {
  static TextStyle _manrope(double size, FontWeight weight) =>
      GoogleFonts.manrope(
        color: Colors.white,
        fontSize: size,
        fontWeight: weight,
      );

  static final TextTheme darkTextTheme = TextTheme(
    bodyLarge: _manrope(15, FontWeight.w500),
    bodyMedium: _manrope(13, FontWeight.w500),
    titleMedium: _manrope(15, FontWeight.w800),
    titleSmall: _manrope(14, FontWeight.w700),
    displayLarge: _manrope(34, FontWeight.w800),
    displayMedium: _manrope(20, FontWeight.w800),
    displaySmall: _manrope(18, FontWeight.w700),
    headlineMedium: _manrope(24, FontWeight.w800),
    headlineSmall: _manrope(20, FontWeight.w800),
    titleLarge: _manrope(18, FontWeight.w800),
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
      colorScheme: scheme,
      primaryColor: tkGradientBlue,
      scaffoldBackgroundColor: tkDarkerBlue,
      textTheme: darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
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
          GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800),
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
