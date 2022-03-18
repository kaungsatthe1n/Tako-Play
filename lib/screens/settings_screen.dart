import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/media_quality_manager.dart';
import '../helpers/webview_manager.dart';
import '../utils/constants.dart';
import '../utils/tako_helper.dart';
import '../widgets/tako_scaffold.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final webViewManagerController = Get.find<WebViewManager>();
    final mediaQualityController = Get.find<MediaQualityManager>();
    mediaQualityController.getVideoQuality();
    final List<String> videoQualities = [
      '1080 P',
      '720 P',
      '480 P',
      '360 P',
    ];
    return TakoScaffoldWithBackButton(
      appBarTitle: 'Settings',
      body: ListView(
        children: [
          GetBuilder(
            init: webViewManagerController,
            initState: (_) {
              webViewManagerController.getVideoPlayerType();
            },
            builder: (_) => SwitchListTile(
              activeColor: tkGradientBlue,
              value: webViewManagerController.isWebView,
              onChanged: webViewManagerController.changeWebViewType,
              title: const Text('Video Player Type'),
              subtitle: const Text('Enable Webview ?'),
            ),
          ),
          ListTile(
            onTap: () {
              Get.bottomSheet(Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qualityListTile(videoQualities[3], mediaQualityController),
                  _qualityListTile(videoQualities[2], mediaQualityController),
                  _qualityListTile(videoQualities[1], mediaQualityController),
                  _qualityListTile(videoQualities[0], mediaQualityController),
                ],
              ));
            },
            hoverColor: Colors.white,
            leading: const Icon(Icons.video_settings_rounded),
            title: const Text('Preferred Media Quality'),
          ),
        ],
      ),
    );
  }

  Widget _qualityListTile(String quality, MediaQualityManager manager) {
    return ListTile(
      title: Text(quality),
      hoverColor: Colors.white,
      leading: manager.defaultQuality == quality ? Icon(Icons.check) : null,
      onTap: () {
        manager.changeMediaQuality(quality);
        Get.close(1);
        takoDebugPrint(manager.defaultQuality);
      },
    );
  }
}
