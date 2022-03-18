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
                    '(--) New Features ~~~ \n\n(-) Added Preferred video quality.\n\n(-) Added Genre to Filter Animes.\n\n(-) Added new icon for (Sub) and (Dub).\n\n(-) Pressing on a genre of the anime will take you to the page with list of anime with that genre.  \n\n(--) Minor Changes ~~~ \n\n(-) Fixed Laggy Animation and Added Animation to some UI.\n\n(-) Fixed Layout Error in Big Screen Device.\n\n(-) Black Screen Issue In WebView Player. '),
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
                Get.dialog(
                    UpdateAlertDialog(downloadLink: updateLink.toString()));
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
