import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('saved: adds a title from details and displays it in the tab',
      (tester) async {
    await launchFixtureApp(tester);
    await openFixtureDetails(tester);

    await scrollDetailUntilVisible(tester, find.text('Save'));
    await tapAndWait(tester, find.text('Save'));
    expect(find.text('Added to bookmark successfully!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await returnToMain(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tapAndWait(tester, find.byType(NavigationDestination).at(2));
    expect(find.text('My library'), findsOneWidget);
    expect(find.text('Ace'), findsOneWidget);
  });
}
