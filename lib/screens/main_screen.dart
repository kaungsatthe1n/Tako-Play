import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/webview_manager.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recent_list_screen.dart';
import '../utils/constants.dart';
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
      appBar: currentIndex.value == 0
          ? null
          : AppBar(
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
              title: Text(
                _titles[currentIndex.value],
                style: GoogleFonts.dmSans(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
            ),
      body: PageView(
        controller: _pageController,
        allowImplicitScrolling: true,
        onPageChanged: (index) => setState(() => currentIndex.value = index),
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() => SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Obx(
          () => Container(
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tkDarkBlue,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFF302D55)),
            ),
            child: Row(
              children: [
                _navigationItem(0, Icons.home_rounded, 'Home'),
                _navigationItem(
                    1, Icons.play_circle_outline_rounded, 'Watchlist'),
                _navigationItem(2, Icons.bookmark_border_rounded, 'Saved'),
              ],
            ),
          ),
        ),
      );

  Widget _navigationItem(int index, IconData icon, String label) {
    final selected = currentIndex.value == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          setState(() => currentIndex.value = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOut,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? tkGradientBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 22,
                  color: selected ? tkDarkerBlue : const Color(0xFFD3D1E5)),
              if (selected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: tkDarkerBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
