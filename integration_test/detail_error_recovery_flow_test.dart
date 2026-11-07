import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  initializeIntegrationTests();

  testWidgets('details: retries a failed episode-list request successfully',
      (tester) async {
    await launchFixtureApp(tester, failFirstDetailRequest: true);
    await openFixtureDetails(tester);

    expect(find.text('We could not load the episode list.'), findsOneWidget);
    await tapAndWait(tester, find.text('Try again'));

    await scrollDetailUntilVisible(tester, find.text('Episodes'));
    expect(find.text('Episodes'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
