import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/media_quality_manager.dart';
import 'package:tako_play/helpers/webview_manager.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('drawer: changes player preferences', (tester) async {
    await launchFixtureApp(tester);

    await tapAndWait(tester, find.byIcon(Icons.grid_view_rounded));
    await tapAndWait(tester, find.text('Settings'));
    expect(find.text('Video Player Type'), findsOneWidget);

    final wasWebViewEnabled = Get.find<WebViewManager>().isWebView;
    await tapAndWait(tester, find.byType(Switch));
    expect(Get.find<WebViewManager>().isWebView, isNot(wasWebViewEnabled));

    await tapAndWait(tester, find.text('Preferred Media Quality'));
    await tapAndWait(tester, find.text('1080 P'));
    expect(Get.find<MediaQualityManager>().defaultQuality, '1080 P');
  });

  testWidgets('drawer: displays app metadata and checks for updates',
      (tester) async {
    await launchFixtureApp(tester);

    await tapAndWait(tester, find.byIcon(Icons.grid_view_rounded));
    await tapAndWait(tester, find.text('About TakoPlay'));

    expect(find.text('About'), findsOneWidget);
    expect(find.text('v1.7.1'), findsOneWidget);
    await tapAndWait(tester, find.text('Check For Update '));
    expect(find.text('No update is available right now.'), findsOneWidget);
  });
}
