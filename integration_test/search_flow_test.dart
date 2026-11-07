import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/widgets/searched_result_anime_card.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('search: debounces a query, displays results, and opens details',
      (tester) async {
    await launchFixtureApp(tester);

    await tapAndWait(tester, find.byIcon(Icons.search_rounded).first);
    expect(find.text('Search'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ace');
    await tester.pump(const Duration(milliseconds: 600));
    await waitForUi(tester);

    expect(find.text('1 results for “Ace”'), findsOneWidget);
    await tapAndWait(tester, find.byType(SearchedResultAnimeCard));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Episodes'), findsOneWidget);
  });
}
