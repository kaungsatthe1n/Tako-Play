// Network Request

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

const String version = 'v1.2.0';
String updateLink = '';
bool isSameVersion = true;
const license = 'MIT License';
const String latestRelease =
    'https://api.github.com/repos/kaungsatthe1n/Tako-Play/releases/latest';

const String baseUrl = 'https://gogoanime.wiki/';
const String search = '/search.html?keyword=';
final mediaFileRegExp =
    RegExp(r"(https)://[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+[.m3u8]");
final resolutionRegExp = RegExp(r"[0-9]+(P)");
// final hostRegExp = RegExp(r"(Server )[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+[,]");

const String takoPlay = 'https://github.com/kaungsatthe1n/Tako-Play';
const String takoTracker = 'https://github.com/kaungsatthe1n/Tako-AnimeTracker';
const String mailing =
    'mailto:parrotksh@gmail.com?subject=[TakoPlay: (Ver: $version)]';
const userAgent =
    "Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36";
const origin = "https://goload.one";
const referer = "https://gogoplay.io";
Map<String, String> header = {
  'User-Agent': userAgent,
  // 'Origin': origin,
  'Referer': referer,
};

// Color

const Color tkDarkBlue = Color(0xFF0D1321);
const Color tkDarkerBlue = Color(0xFF060B16);
const Color tkDarkGreen = Color(0xFF1D4C4F);
const Color tkLightGreen = Color(0xFF12B471);
const Color tkGrey = Color(0xFF323435);
const Color tkGradientBlue = Color(0xFF133F6E);
const Color tkGradientBlack = Color(0xFF28313B);

// ScreenUtil

double screenWidth = ScreenUtil().screenWidth;
double screenHeight = ScreenUtil().screenHeight;

const loadingIndicator = SpinKitFadingCube(
  color: tkLightGreen,
);
