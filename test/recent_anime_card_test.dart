import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/recent_anime_card.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('continues a partially watched episode from its saved position',
      (tester) async {
    final manager = RecentWatchManager(database: _RecentStore());
    Get.put(manager);
    await manager.saveProgress(
        animeId: 'show',
        episodeUrl: 'https://example.com/episode',
        episodeNumber: '1',
        positionMillis: 500,
        durationMillis: 1000);
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(
          body: RecentAnimeCard(
        id: 'show',
        name: 'Show',
        currentEp: 'Episode 1',
        imageUrl: '',
        epUrl: 'https://example.com/episode',
      )),
      getPages: [
        GetPage(
            name: Routes.mediaFetchScreen,
            page: () => const Scaffold(body: Text('Player')))
      ],
    ));
    await tester.tap(find.byType(RecentAnimeCard));
    await tester.pumpAndSettle();
    expect(Get.arguments['resumePosition'], const Duration(milliseconds: 500));
  });

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

class _RecentStore implements RecentAnimeStore {
  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => [];
  @override
  Future<void> insert(RecentAnime anime) async {}
  @override
  Future<int> remove(String id) async => 0;
  @override
  Future<int> removeAll() async => 0;
}
