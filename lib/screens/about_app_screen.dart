import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/tako_scaffold.dart';
import '../widgets/update_alert_dialog.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TakoScaffoldWithBackButton(
      appBarTitle: 'About',
      body: ListView(
        children: [
          const ListTile(
            title: Text('Version'),
            subtitle: Text(version),
          ),
          const ListTile(
            title: Text('Creator'),
            subtitle: Text('Kaung Satt Hein'),
          ),
          const ListTile(
            title: Text('Contributors'),
            subtitle: Text('DDavidPrime, CntrlX'),
          ),
          ListTile(
            onTap: () => _launchUrl(takoPlay),
            title: const Text('Source Code'),
            subtitle: const Text(takoPlay),
          ),
          const ListTile(
            title: Text('License'),
            subtitle: Text(license),
          ),
          ListTile(
            onTap: () {
              if (isSameVersion) {
                Get.dialog(const AlertDialog(
                  backgroundColor: tkDarkBlue,
                  content: Text('No Update Available'),
                ));
              } else {
                Get.dialog(
                    UpdateAlertDialog(downloadLink: updateLink.toString()));
              }
            },
            title: const Text('Check For Update '),
          ),
          ListTile(
            onTap: () => _launchUrl(mailing),
            title: const Text('Contact Developer'),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchUrl(url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
