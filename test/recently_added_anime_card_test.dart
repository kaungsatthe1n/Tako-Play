import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/recently_added_anime_card.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('opens episode details instead of sending an anime URL to player',
      (tester) async {
    const anime = Anime(
      id: 'show-1',
      name: 'Test title',
      imageUrl: 'https://example.com/poster.jpg',
      animeUrl: 'https://catalog.example.com/anime/test-title',
      currentEp: 'EP 4',
    );
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: RecentlyAddedAnimeCard(anime: anime)),
        getPages: [
          GetPage(
            name: Routes.videoListScreen,
            page: () => const Scaffold(body: Text('Episode details')),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(RecentlyAddedAnimeCard));
    await tester.pumpAndSettle();

    expect(find.text('Episode details'), findsOneWidget);
  });
}
