// Network Request

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const String version = 'v1.0.1';
bool isSameVersion = true;
const license = 'MIT License';
const String latestRelease =
    'https://api.github.com/repos/kaungsatthe1n/Tako-Play/releases/latest';
const String baseUrl = 'https://gogoplay1.com/';
const String search = '/search.html?keyword=';
final mediaFileRegExp =
    RegExp(r"(https)://[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+[.m3u8]");

const String takoPlay = 'https://github.com/kaungsatthe1n/Tako-Play';
const String takoTracker = 'https://github.com/kaungsatthe1n/Tako-AnimeTracker';
const String mailing =
    'mailto:parrotksh@gmail.com?subject=[TakoPlay: (Ver: $version)]';

const userAgent =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36";
const origin = "https://goload.one";
const referer = "https://goload.one";
Map<String, String> header = {
  'User-Agent': userAgent,
  'Origin': origin,
  'Referer': referer,
};

// Color

const Color tkDarkBlue = Color(0xFF0D1321);
const Color tkDarkerBlue = Color(0xFF060B16);
const Color tkDarkGreen = Color(0xFF1D4C4F);
const Color tkLightGreen = Color(0xFF28B67E);
const Color tkGrey = Color(0xFFD3DCDE);

// ScreenUtil

double screenWidth = ScreenUtil().screenWidth;
double screenHeight = ScreenUtil().screenHeight;