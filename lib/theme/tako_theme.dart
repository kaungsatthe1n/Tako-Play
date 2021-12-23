import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class TakoTheme {
  static TextTheme darkTextTheme = TextTheme(
    bodyText1: GoogleFonts.roboto(
      fontSize: 15.0,
      fontWeight: FontWeight.normal,
      color: Colors.white,
    ),
    subtitle1: GoogleFonts.roboto(
      fontSize: 15.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    subtitle2: GoogleFonts.roboto(
      fontSize: 17.0,
      color: Colors.white,
    ),
    headline1: GoogleFonts.roboto(
      fontSize: 31.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headline2: GoogleFonts.roboto(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    headline3: GoogleFonts.roboto(
      fontSize: 19.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    headline4: GoogleFonts.roboto(
      fontSize: 22.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    headline5: GoogleFonts.roboto(
      fontSize: 19.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    headline6: GoogleFonts.roboto(
      fontSize: 19.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      backgroundColor: Colors.black,
      scaffoldBackgroundColor: tkDarkerBlue,
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.white,
        backgroundColor: tkDarkBlue,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: tkLightGreen,
        unselectedItemColor: tkGrey,
        backgroundColor: tkDarkBlue,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.all(Colors.black),
        fillColor: MaterialStateProperty.all(tkLightGreen.withAlpha(205)),
      ),
      textTheme: darkTextTheme,
    );
  }
}
