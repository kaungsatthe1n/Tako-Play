import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
            title: const Text('What\'s the update ?'),
            onTap: () {
              Get.dialog(const AlertDialog(
                backgroundColor: tkDarkBlue,
                content: Text(
                    '(-) Video Player is paused when the app is in the inactive mode.\n\n(-) Video Controls Layer is Visible when the app is back to the active mode.\n\n(-) Recently clicked episode number will be mark.'),
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
