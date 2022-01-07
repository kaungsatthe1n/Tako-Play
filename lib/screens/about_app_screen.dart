import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Version'),
            subtitle: Text(version),
          ),
          const ListTile(
            title: Text('Developer'),
            subtitle: Text('Kaung Satt Hein'),
          ),
          ListTile(
            onTap: () => launch(takoPlay),
            title: const Text('Source Code'),
            subtitle: const Text(takoPlay),
          ),
          const ListTile(
            title: Text('License'),
            subtitle: Text(license),
          ),
          ListTile(
            title: const Text('What\'s the update ?'),
            onTap: () {
              Get.dialog(const AlertDialog(
                backgroundColor: tkDarkBlue,
                content: Text(
                    '(-) CDN Server(No Ads) is back now.\n\n(-) Anime Details (Release Date , Status , Genres) is Added.\n\n(-) You can now Bookmark your favourite Anime.\n\n(-) Search Feature is enhanced.\n\n(-) Toggle Button is added for choosing video player type.'),
              ));
            },
          ),
          ListTile(
            onTap: () {
              if (isSameVersion) {
                Get.dialog(const AlertDialog(
                  backgroundColor: tkDarkBlue,
                  content: Text('No Update Available'),
                ));
              } else {
                Get.dialog(AlertDialog(
                  backgroundColor: tkDarkBlue,
                  content: SizedBox(
                    height: (screenHeight * .15).h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New Update is Available\n'),
                        MaterialButton(
                            elevation: 5,
                            color: tkLightGreen.withAlpha(200),
                            child: const Text('Update'),
                            onPressed: () => launch(updateLink.toString())),
                      ],
                    ),
                  ),
                ));
              }
            },
            title: const Text('Check For Update '),
          ),
          ListTile(
            onTap: () => launch(mailing),
            title: const Text('Contact Developer'),
          ),
        ],
      ),
    );
  }
}
