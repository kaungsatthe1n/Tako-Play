import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/webview_manager.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recent_list_screen.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/anime_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebViewManager webViewManagerController;
  late final PageController _pageController;
  final currentIndex = 0.obs;

  final List<Widget> _pages = [
    const HomeScreen(),
    RecentListScreen(),
    BookMarksScreen(),
  ];

  final _titles = const ['Discover', 'Continue watching', 'My library'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    webViewManagerController = Get.find<WebViewManager>();
    webViewManagerController.getVideoPlayerType();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AnimeDrawer(),
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 74,
        leadingWidth: 72,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tkDarkBlue,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.grid_view_rounded, size: 20),
            ),
          ),
        ),
        title: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              _titles[currentIndex.value],
              key: ValueKey(currentIndex.value),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -.7,
              ),
            ),
          ),
        ),
        actions: [
          Obx(
            () => currentIndex.value == 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      onPressed: () => Get.toNamed(Routes.searchScreen),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tkGradientBlue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  )
                : const SizedBox(width: 16),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        allowImplicitScrolling: true,
        onPageChanged: (index) => currentIndex.value = index,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Obx(
          () => ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 68,
              selectedIndex: currentIndex.value,
              onDestinationSelected: (index) {
                currentIndex.value = index;
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.play_circle_outline_rounded),
                  selectedIcon: Icon(Icons.play_circle_fill_rounded),
                  label: 'Watchlist',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_outline_rounded),
                  selectedIcon: Icon(Icons.bookmark_rounded),
                  label: 'Saved',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
