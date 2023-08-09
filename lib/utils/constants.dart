import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Collection of all app related constants go here

const String version = 'v1.6.3';
String updateLink = '';
bool isSameVersion = true;
const license = 'MIT License';
const String latestRelease =
    'https://api.github.com/repos/kaungsatthe1n/Tako-Play/releases/latest';

const String baseUrl = 'https://gogoanime.wiki/';
const String search = '/search.html?keyword=';
final mediaFileRegExp =
    RegExp(r"(https)://[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+[.m3u8]");
final resolutionRegExp = RegExp(r'[0-9]+(P)');
// final hostRegExp = RegExp(r"(Server )[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+[,]");

const String takoPlay = 'https://github.com/kaungsatthe1n/Tako-Play';
const String takoTracker = 'https://github.com/kaungsatthe1n/Tako-AnimeTracker';
const String mailing =
    'mailto:parrotksh@gmail.com?subject=[TakoPlay: (Ver: $version)]';
const userAgent =
    'Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36';
const origin = 'https://goload.one';
const referer = 'https://gogoplay.io';
Map<String, String> header = {
  'User-Agent': userAgent,
  // 'Origin': origin,
  'Referer': referer,
};

const String ACTION = '$baseUrl/genre/action';
const String ADVENTURE = '$baseUrl/genre/adventure';
const String CARS = '$baseUrl/genre/cars';
const String COMEDY = '$baseUrl/genre/comedy';
const String CRIME = '$baseUrl/genre/crime';
const String DEMENTIA = '$baseUrl/genre/dementia';
const String DEMONS = '$baseUrl/genre/demons';
const String DRAMA = '$baseUrl/genre/drama';
const String DUB = '$baseUrl/genre/dub';
const String ECCHI = '$baseUrl/genre/ecchi';
const String FAMILY = '$baseUrl/genre/family';
const String FANTASY = '$baseUrl/genre/fantasy';
const String GAME = '$baseUrl/genre/game';
const String HAREM = '$baseUrl/genre/harem';
const String HISTORICAL = '$baseUrl/genre/historical';
const String HORROR = '$baseUrl/genre/horror';
const String JOSEI = '$baseUrl/genre/josei';
const String KIDS = '$baseUrl/genre/kids';
const String MAGIC = '$baseUrl/genre/magic';
const String MECHA = '$baseUrl/genre/mecha';
const String MILITARY = '$baseUrl/genre/military';
const String MUSIC = '$baseUrl/genre/music';
const String MYSTERY = '$baseUrl/genre/mystery';
const String PARODY = '$baseUrl/genre/parody';
const String POLICE = '$baseUrl/genre/police';
const String PSYCHOLOGICAL = '$baseUrl/genre/psychological';
const String ROMANCE = '$baseUrl/genre/romance';
const String SAMURAI = '$baseUrl/genre/saurai';
const String SCHOOL = '$baseUrl/genre/school';
const String SCI_FI = '$baseUrl/genre/sci-fi';
const String SEINEN = '$baseUrl/genre/seinen';
const String SHOUJO = '$baseUrl/genre/shoujo';
const String SHOUJO_AI = '$baseUrl/genre/shoujo-ai';
const String SHOUNEN = '$baseUrl/genre/shounen';
const String SHOUNEN_AI = '$baseUrl/genre/shounen-ai';
const String SLICE_OF_LIFE = '$baseUrl/genre/slice-of-life';
const String SPACE = '$baseUrl/genre/space';
const String SPORTS = '$baseUrl/genre/sports';
const String SUPER_POWER = '$baseUrl/genre/super-power';
const String SUPER_NATURAL = '$baseUrl/genre/super-natural';
const String SUSPENSE = '$baseUrl/genre/suspense';
const String THRILLER = '$baseUrl/genre/thriller';
const String VAMPIRE = '$baseUrl/genre/vampire';
const String YAOI = '$baseUrl/genre/yaoi';
const String YURI = '$baseUrl/genre/yuri';

// Color

const Color tkDarkBlue = Color(0xFF0D1321);
const Color tkDarkerBlue = Color(0xFF060B16);
const Color tkDarkGreen = Color(0xFF1D4C4F);
const Color tkGrey = Color(0xFF323435);
const Color tkGradientBlue = Color(0xFF133F6E);
const Color tkGradientBlack = Color(0xFF28313B);

const loadingIndicator = SpinKitSquareCircle(
  color: Colors.white,
);

const int takoAnimationDuration = 1800;
