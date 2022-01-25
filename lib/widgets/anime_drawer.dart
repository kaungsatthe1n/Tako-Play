import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/webview_manager.dart';
import 'package:tako_play/theme/tako_theme.dart';
import 'package:tako_play/utils/constants.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimeDrawer extends StatelessWidget {
  const AnimeDrawer({
    Key? key,
    required this.webViewManagerController,
  }) : super(key: key);

  final WebViewManager webViewManagerController;

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
    );
  }
}
