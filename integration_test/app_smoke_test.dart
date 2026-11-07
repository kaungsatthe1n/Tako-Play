import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tako_play/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches and navigates through the primary app flow',
      (tester) async {
    await app.main();
    await _waitForTransition(tester);
    await _dismissUpdatePrompt(tester);

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await _waitForTransition(tester);
    expect(find.text('My library'), findsOneWidget);

    await tester.tap(find.text('Watchlist'));
    await _waitForTransition(tester);
    expect(find.text('Continue watching'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await _waitForTransition(tester);
    expect(find.text('Discover'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await _waitForTransition(tester);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Search anime, movies, genres…'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await _waitForTransition(tester);
    expect(find.text('Discover'), findsOneWidget);
  });
}

Future<void> _waitForTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _dismissUpdatePrompt(WidgetTester tester) async {
  final cancelButton = find.widgetWithText(MaterialButton, 'Cancel');
  if (cancelButton.evaluate().isEmpty) return;

  await tester.tap(cancelButton);
  await _waitForTransition(tester);
}
