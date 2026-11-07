import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/widgets/searched_result_anime_card.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('home: loads fixture catalog, details, and genre pagination',
      (tester) async {
    await launchFixtureApp(tester);

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Popular now'), findsOneWidget);
    expect(find.text('New episodes'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Ace'), findsWidgets);

    await openFixtureDetails(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('We could not load the episode list.'), findsNothing);
    expect(find.byType(Scrollable), findsWidgets);

    await scrollDetailUntilVisible(tester, find.text('About this title'));
    await tapAndWait(tester, find.text('About this title'));
    expect(find.text('A deterministic fixture synopsis.'), findsOneWidget);

    await scrollDetailUntilVisible(tester, find.text('Action').first);
    await tapAndWait(tester, find.text('Action').first);
    expect(find.widgetWithText(AppBar, 'Action'), findsOneWidget);
    expect(find.byType(SearchedResultAnimeCard), findsOneWidget);

    await tapAndWait(tester, find.text('Next'));
    expect(find.text('No more titles in this genre.'), findsOneWidget);
  });
}
