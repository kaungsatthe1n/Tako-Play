import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/anime_drawer.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('renders the drawer without a genres shortcut', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: AnimeDrawer()),
        getPages: [
          GetPage(
            name: Routes.settingsScreen,
            page: () => const Scaffold(body: Text('Settings destination')),
          ),
          GetPage(
            name: Routes.aboutAppScreen,
            page: () => const Scaffold(body: Text('About destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TakoPlay'), findsOneWidget);
    expect(find.text('Your anime space'), findsOneWidget);
    expect(find.text('Genres'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About TakoPlay'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings destination'), findsOneWidget);
  });
}
