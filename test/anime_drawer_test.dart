import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/anime_drawer.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('renders the navigation drawer and opens genres', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: AnimeDrawer()),
        getPages: [
          GetPage(
            name: Routes.genreSelectionScreen,
            page: () => const Scaffold(body: Text('Genres destination')),
          ),
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
    expect(find.text('Genres'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About TakoPlay'), findsOneWidget);

    await tester.tap(find.text('Genres'));
    await tester.pumpAndSettle();
    expect(find.text('Genres destination'), findsOneWidget);
  });
}
