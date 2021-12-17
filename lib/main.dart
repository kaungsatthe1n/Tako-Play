import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:tako_play/screens/about_app_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/video_list_screen.dart';
import '../screens/video_player_screen.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/routes.dart';

void main() {
  _setUpLogging();
  runApp(const MyApp());
}

void _setUpLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => RequestService.create(),
          dispose: (_, RequestService service) => service.client.dispose(),
        ),
      ],
      child: Sizer(
        builder: (context, _, __) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TakoPlay',
          theme: TakoTheme.dark(),
          initialRoute: '/',
          getPages: [
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
              name: Routes.videoListScreen,
              page: () => const VideoListScreen(),
            ),
            GetPage(
              name: Routes.videoPlayerScreen,
              page: () => const VideoPlayerScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
