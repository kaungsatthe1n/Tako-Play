import 'package:flutter/material.dart';

/// Collection of all app related constants go here

const String version = 'v1.8.0';
const license = 'MIT License';
const String latestRelease =
    'https://api.github.com/repos/kaungsatthe1n/Tako-Play/releases/latest';

/// Catalog source. Override for an owned API or staging source with:
/// `--dart-define=SOURCE_BASE_URL=https://catalog.example.com`.
const String sourceBaseUrl = String.fromEnvironment(
  'SOURCE_BASE_URL',
  defaultValue: 'https://gogoanimes.org',
);
const String baseUrl = '$sourceBaseUrl/';
const String search = '?s=';
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
const origin = sourceBaseUrl;
const referer = '$sourceBaseUrl/';
final Map<String, String> header = {
  'User-Agent': userAgent,
  // 'Origin': origin,
  'Referer': referer,
};

const String ACTION = '$sourceBaseUrl/genre/action/';
const String ADVENTURE = '$sourceBaseUrl/genre/adventure/';
const String CARS = '$sourceBaseUrl/genres/cars/';
const String COMEDY = '$sourceBaseUrl/genre/comedy/';
const String CRIME = '$sourceBaseUrl/genres/crime/';
const String DEMENTIA = '$sourceBaseUrl/genres/dementia/';
const String DEMONS = '$sourceBaseUrl/genres/demons/';
const String DRAMA = '$sourceBaseUrl/genre/drama/';
const String DUB = '$sourceBaseUrl/genres/dub/';
const String ECCHI = '$sourceBaseUrl/genre/ecchi/';
const String FAMILY = '$sourceBaseUrl/genres/family/';
const String FANTASY = '$sourceBaseUrl/genre/fantasy/';
const String GAME = '$sourceBaseUrl/genres/game/';
const String HAREM = '$sourceBaseUrl/genres/harem/';
const String HISTORICAL = '$sourceBaseUrl/genres/historical/';
const String HORROR = '$sourceBaseUrl/genre/horror/';
const String JOSEI = '$sourceBaseUrl/genres/josei/';
const String KIDS = '$sourceBaseUrl/genres/kids/';
const String MAGIC = '$sourceBaseUrl/genres/magic/';
const String MECHA = '$sourceBaseUrl/genre/mecha/';
const String MILITARY = '$sourceBaseUrl/genres/military/';
const String MUSIC = '$sourceBaseUrl/genre/music/';
const String MYSTERY = '$sourceBaseUrl/genre/mystery/';
const String PARODY = '$sourceBaseUrl/genres/parody/';
const String POLICE = '$sourceBaseUrl/genres/police/';
const String PSYCHOLOGICAL = '$sourceBaseUrl/genre/psychological/';
const String ROMANCE = '$sourceBaseUrl/genre/romance/';
const String SAMURAI = '$sourceBaseUrl/genres/samurai/';
const String SCHOOL = '$sourceBaseUrl/genres/school/';
const String SCI_FI = '$sourceBaseUrl/genre/sci-fi/';
const String SEINEN = '$sourceBaseUrl/genres/seinen/';
const String SHOUJO = '$sourceBaseUrl/genres/shoujo/';
const String SHOUJO_AI = '$sourceBaseUrl/genres/shoujo-ai/';
const String SHOUNEN = '$sourceBaseUrl/genres/shounen/';
const String SHOUNEN_AI = '$sourceBaseUrl/genres/shounen-ai/';
const String SLICE_OF_LIFE = '$sourceBaseUrl/genre/slice-of-life/';
const String SPACE = '$sourceBaseUrl/genres/space/';
const String SPORTS = '$sourceBaseUrl/genre/sports/';
const String SUPER_POWER = '$sourceBaseUrl/genres/super-power/';
const String SUPER_NATURAL = '$sourceBaseUrl/genre/supernatural/';
const String SUSPENSE = '$sourceBaseUrl/genres/suspense/';
const String THRILLER = '$sourceBaseUrl/genre/thriller/';
const String VAMPIRE = '$sourceBaseUrl/genres/vampire/';
const String YAOI = '$sourceBaseUrl/genres/yaoi/';
const String YURI = '$sourceBaseUrl/genres/yuri/';

// Color

const Color tkDarkBlue = Color(0xFF15182B);
const Color tkDarkerBlue = Color(0xFF090A12);
const Color tkDarkGreen = Color(0xFF1D4C4F);
const Color tkGrey = Color(0xFF292C3C);
const Color tkGradientBlue = Color(0xFF7867F7);
const Color tkGradientBlack = Color(0xFF1A1D31);
const Color tkCoral = Color(0xFFFF6B6B);
const Color tkMutedText = Color(0xFFA9ADC3);

const int takoAnimationDuration = 1800;
