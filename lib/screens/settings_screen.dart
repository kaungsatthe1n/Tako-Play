import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/webview_manager.dart';
import '../utils/constants.dart';
import '../widgets/tako_scaffold.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final webViewManagerController = Get.find<WebViewManager>();
    return TakoScaffoldWithBackButton(
      appBarTitle: 'Settings',
      body: ListView(
        children: [
          GetBuilder(
            init: webViewManagerController,
            builder: (_) => SwitchListTile(
              activeThumbColor: tkGradientBlue,
              value: webViewManagerController.isWebView,
              onChanged: webViewManagerController.changeWebViewType,
              title: const Text('Use browser player'),
              subtitle: const Text(
                'Turn this on only if a video will not play',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
