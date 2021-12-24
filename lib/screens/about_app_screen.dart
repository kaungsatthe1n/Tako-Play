import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tako_play/theme/tako_theme.dart';
import 'package:tako_play/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

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
            title: const Text('Where\'s the Video Player with No Ads?'),
            onTap: () {
              Get.dialog(AlertDialog(
                backgroundColor: tkDarkBlue,
                content: SizedBox(
                  height: (screenHeight * .45).h,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notice',
                        style: TakoTheme.darkTextTheme.headline1!
                            .copyWith(color: tkLightGreen),
                      ),
                      Text(
                        'Dear TakoPlay Users, \n\n* Sadly, CDN Server(No Ads Popup) is no longer available as the Website used by this app has updated their source code !\n\n* WebView is still Working Fine.',
                        style: TakoTheme.darkTextTheme.headline3,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MaterialButton(
                              color: tkLightGreen.withAlpha(200),
                              child: const Text('Close'),
                              onPressed: () {
                                Get.back();
                              }),
                        ],
                      )
                    ],
                  ),
                ),
              ));
            },
          ),
          ListTile(
            title: const Text('What\'s the update ?'),
            onTap: () {
              Get.dialog(const AlertDialog(
                backgroundColor: tkDarkBlue,
                content: Text(
                    '(-) Only WebView(Contains Ads popup) is Available.\n\n (-) Fixed Animes from Recently Added and Ongoing are unable to watch.\n\n(-) Fixed WebView Video AspectRatio.'),
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
