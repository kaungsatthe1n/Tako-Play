import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/recent_anime.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('watchlist: displays and removes a recent episode',
      (tester) async {
    await launchFixtureApp(tester);
    await Get.find<RecentWatchManager>().addAnimeToRecent(
      RecentAnime(
        id: 'fixture-hero',
        name: 'Ace',
        currentEp: 'Episode 1',
        imageUrl: '',
        epUrl: 'https://gogoanime9.ro/test-hero-episode-1',
      ),
    );
    await tapAndWait(tester, find.byType(NavigationDestination).at(1));

    expect(find.text('Continue watching'), findsWidgets);
    expect(find.text('Episode 1'), findsOneWidget);
    expect(find.text('Ace'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('fixture-hero')),
      const Offset(-400, 0),
    );
    await waitForUi(tester);
    expect(find.text('Nothing in your watchlist yet'), findsOneWidget);
  });
}
