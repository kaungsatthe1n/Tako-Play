import 'package:get/get.dart';
import 'package:tako_play/screens/about_app_screen.dart';
import 'package:tako_play/screens/home_screen.dart';
import 'package:tako_play/screens/main_screen.dart';
import 'package:tako_play/screens/media_fetch_screen.dart';
import 'package:tako_play/screens/no_internet_screen.dart';
import 'package:tako_play/screens/recent_list_screen.dart';
import 'package:tako_play/screens/search_screen.dart';
import 'package:tako_play/screens/video_list_screen.dart';
import 'package:tako_play/screens/video_player_screen.dart';
import 'package:tako_play/screens/webview_screen.dart';
import 'package:tako_play/utils/routes.dart';

class TakoRoute {
  TakoRoute._();
  static final pages = [
    GetPage(
      name: Routes.mainScreen,
      page: () => const MainScreen(),
    ),
    GetPage(
      name: Routes.homeScreen,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: Routes.aboutAppScreen,
      page: () => const AboutAppScreen(),
    ),
    GetPage(
      name: Routes.searchScreen,
      page: () => const SearchScreen(),
    ),
    GetPage(
      name: Routes.recentListScreen,
      page: () => RecentListScreen(),
    ),
    GetPage(
      name: Routes.videoListScreen,
      page: () => const VideoListScreen(),
    ),
    GetPage(
      name: Routes.mediaFetchScreen,
      page: () => const MediaFetchScreen(),
    ),
    GetPage(
      name: Routes.videoPlayerScreen,
      page: () => const VideoPlayerScreen(),
    ),
    GetPage(
      name: Routes.webViewScreen,
      page: () => const WebViewScreen(),
    ),
    GetPage(
      name: Routes.noInternetScreen,
      page: () => const NoInternetScreen(),
    ),
  ];
}
