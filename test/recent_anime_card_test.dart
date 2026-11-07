import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/recent_anime_card.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('opens legacy detail URLs through the episode list',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(
          body: RecentAnimeCard(
            id: 'show-1',
            name: 'Legacy title',
            currentEp: 'Episode 1',
            imageUrl: 'https://example.com/poster.jpg',
            epUrl: 'https://gogoanime.wiki/category/legacy-title',
          ),
        ),
        getPages: [
          GetPage(
            name: Routes.videoListScreen,
            page: () => const Scaffold(body: Text('Episode details')),
          ),
          GetPage(
            name: Routes.mediaFetchScreen,
            page: () => const Scaffold(body: Text('Player')),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(RecentAnimeCard));
    await tester.pumpAndSettle();

    expect(find.text('Episode details'), findsOneWidget);
    expect(find.text('Player'), findsNothing);
  });
}
