import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import '../helpers/webview_provider.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/home_screen.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var currentIndex = 0.obs;
  var title = 'Home'.obs;
  final webViewManagerController = Get.put(WebViewManagerController());
  final List<Widget> _pages = [
    const HomeScreen(),
    const BookMarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: tkDarkBlue,
          child: ListView(
            children: [
              SizedBox(
                height: (screenHeight * .39).h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.h),
                        child: Image.asset(
                          'assets/images/rem.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black45,
                    ),
                    Positioned(
                      right: 5,
                      left: 5,
                      bottom: 0,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        height: (screenHeight * .07).h,
                        decoration: BoxDecoration(
                            color: tkLightGreen.withOpacity(.7),
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10))),
                        child: Text(
                          'TakoPlay',
                          style: TakoTheme.darkTextTheme.headline4,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: (screenHeight * .02).h,
              ),
              ListTile(
                hoverColor: Colors.white,
                onTap: () => launch(takoTracker),
                leading: const Icon(Icons.apps_outlined),
                title: const Text('Other App'),
              ),
              ListTile(
                onTap: () => Get.toNamed(Routes.aboutAppScreen),
                hoverColor: Colors.white,
                leading: const Icon(Icons.info),
                title: const Text('About TakoPlay'),
              ),
              GetBuilder(
                init: webViewManagerController,
                initState: (_) {
                  webViewManagerController.getVideoPlayerType();
                },
                builder: (_) => SwitchListTile(
                  activeColor: tkLightGreen,
                  value: webViewManagerController.isWebView,
                  onChanged: webViewManagerController.changeWebViewType,
                  title: const Text('Video Player Type'),
                  subtitle: const Text('Enable Webview ?'),
                ),
              )
            ],
          ),
        ),
      ),
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
        centerTitle: true,
        title: Obx(() => Text(title.value)),
      ),
      body: Obx(
        () => IndexedStack(
          children: _pages,
          index: currentIndex.value,
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: currentIndex.value,
          onTap: (index) {
            currentIndex.value = index;
            if (currentIndex.value == 0) {
              title.value = 'Home';
            } else if (currentIndex.value == 1) {
              title.value = 'BookMarks';
            } else {}
          },
          selectedItemColor: tkLightGreen,
          unselectedItemColor: tkGrey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'BookMarks',
            ),
          ],
        ),
      ),
    );
  }
}
