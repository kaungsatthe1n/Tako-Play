import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/webview_manager.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('drawer: changes browser player preference', (tester) async {
    await launchFixtureApp(tester);

    await tapAndWait(tester, find.byIcon(Icons.grid_view_rounded));
    await tapAndWait(tester, find.text('Settings'));
    expect(find.text('Use browser player'), findsOneWidget);

    final wasWebViewEnabled = Get.find<WebViewManager>().isWebView;
    await tapAndWait(tester, find.byType(Switch));
    expect(Get.find<WebViewManager>().isWebView, isNot(wasWebViewEnabled));
  });

  testWidgets('drawer: displays app metadata and checks for updates',
      (tester) async {
    await launchFixtureApp(tester);

    await tapAndWait(tester, find.byIcon(Icons.grid_view_rounded));
    await tapAndWait(tester, find.text('About TakoPlay'));

    expect(find.text('About'), findsOneWidget);
    expect(find.text('v1.8.0'), findsOneWidget);
    await tapAndWait(tester, find.text('Check For Update '));
    expect(find.text('No update is available right now.'), findsOneWidget);
  });
}
