import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('episode: records recents and exposes a retryable handoff error',
      (tester) async {
    await launchFixtureApp(tester, failEpisodeEmbedRequest: true);
    await openFixtureDetails(tester);

    final episode = find.byKey(
      const ValueKey('https://gogoanime9.ro/test-hero-episode-1'),
    );
    await scrollDetailUntilVisible(tester, episode);
    await tapAndWait(tester, episode);

    expect(find.text("Episode can't be fetched"), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(
        Get.find<RecentWatchManager>().animeList.single.currentEp, 'Episode 1');

    await tapAndWait(tester, find.text('Try Again'));
    expect(find.text("Episode can't be fetched"), findsOneWidget);
  });
}
