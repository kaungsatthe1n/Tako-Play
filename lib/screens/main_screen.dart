import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/webview_manager.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recent_list_screen.dart';
import '../utils/routes.dart';
import '../widgets/anime_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebViewManager webViewManagerController;
  var currentIndex = 0.obs;
  var title = 'Home'.obs;

  final List<Widget> _pages = [
    const HomeScreen(),
    RecentListScreen(),
    BookMarksScreen(),
  ];

  @override
  void initState() {
    super.initState();

    webViewManagerController = Get.find<WebViewManager>();

    // Make sure we only call this once during main screen initialization to
    // also properly initialize the webView status
    webViewManagerController.getVideoPlayerType();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AnimeDrawer(),
      appBar: AppBar(
        actions: [
          Obx(
            () => currentIndex.value == 0
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: IconButton(
                        onPressed: () {
                          Get.toNamed(Routes.searchScreen);
                        },
                        icon: const Icon(Icons.search)),
                  )
                : const SizedBox(),
          )
        ],
        title: Obx(() => Text(title.value)),
      ),
      body: Obx(
        () => IndexedStack(
          index: currentIndex.value,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          backgroundColor: Colors.black45,
          elevation: 0,
          currentIndex: currentIndex.value,
          onTap: (index) {
            currentIndex.value = index;
            if (currentIndex.value == 0) {
              title.value = 'Home';
            } else if (currentIndex.value == 1) {
              title.value = 'Recent';
            } else {
              title.value = 'BookMarks';
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(currentIndex.value == 0
                  ? Icons.home_filled
                  : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex.value == 1
                  ? Icons.access_time_filled
                  : Icons.access_time_outlined),
              label: 'Recent',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex.value == 2
                  ? Icons.bookmark
                  : Icons.bookmark_outline),
              label: 'BookMarks',
            ),
          ],
        ),
      ),
    );
  }
}
