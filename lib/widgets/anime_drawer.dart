import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class AnimeDrawer extends StatelessWidget {
  const AnimeDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: tkDarkerBlue,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
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
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      height: 60,
                      decoration: BoxDecoration(
                          color: tkDarkBlue.withOpacity(.7),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10))),
                      child: Text(
                        'TakoPlay',
                        style: TakoTheme.darkTextTheme.headlineMedium,
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ListTile(
              hoverColor: Colors.white,
              onTap: () => _launchUrl(takoTracker),
              leading: const Icon(Icons.apps_outlined),
              title: const Text('Other App'),
            ),
            ListTile(
              onTap: () => Get.toNamed(Routes.aboutAppScreen),
              hoverColor: Colors.white,
              leading: const Icon(Icons.info),
              title: const Text('About TakoPlay'),
            ),
            ListTile(
              onTap: () => Get.toNamed(Routes.genreSelectionScreen),
              hoverColor: Colors.white,
              leading: const Icon(Icons.list_outlined),
              title: const Text('Genres'),
            ),
            ListTile(
              onTap: () => Get.toNamed(Routes.settingsScreen),
              hoverColor: Colors.white,
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchUrl(url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
