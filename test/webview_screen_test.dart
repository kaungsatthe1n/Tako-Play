import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/screens/webview_screen.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('rejects an invalid player handoff URL', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: _LaunchWebView()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('This video link is unavailable.'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
  });
}

class _LaunchWebView extends StatelessWidget {
  const _LaunchWebView();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const WebViewScreen(),
              arguments: {'mediaUrl': 'intent://not-a-player'},
            ),
            child: const Text('Open'),
          ),
        ),
      );
}
