import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/screens/search_screen.dart';
import 'package:tako_play/services/request_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async => Get.reset());

  testWidgets('shows catalog search results after the debounce interval',
      (tester) async {
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_searchIndex, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));

    await tester.enterText(find.byType(TextField), 'hero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Hero Show'), findsOneWidget);
    expect(find.textContaining('1 results for'), findsOneWidget);
  });

  testWidgets('shows a retryable error when search fails', (tester) async {
    Get.put(RequestService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));

    await tester.enterText(find.byType(TextField), 'hero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Search failed. Check your connection and try again.'),
        findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('renders saved recent searches before a new query',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'takoRecentSearches': ['One Piece'],
    });
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_searchIndex, 200)),
    ));

    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));
    await tester.pump();

    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('One Piece'), findsOneWidget);
  });

  testWidgets('dismisses the keyboard when tapping outside the search field',
      (tester) async {
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_searchIndex, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));
    await tester.pump();

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(10, 400));
    await tester.pump();

    expect(editableText.focusNode.hasFocus, isFalse);
  });

  testWidgets('uses, deletes, and persists recent searches', (tester) async {
    SharedPreferences.setMockInitialValues({
      'takoRecentSearches': ['One Piece', 'Naruto'],
    });
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_searchIndex, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));
    await tester.pump();

    await tester.tap(find.text('One Piece'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'hero');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(
      (await SharedPreferences.getInstance())
          .getStringList('takoRecentSearches')
          ?.first,
      'hero',
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
            of: find.text('Naruto'), matching: find.byType(ListTile)),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Naruto'), findsNothing);
  });

  testWidgets('shows the no-results state for a completed empty catalogue',
      (tester) async {
    Get.put(RequestService(
      client: MockClient((_) async => http.Response('[]', 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'hero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('No matches found'), findsOneWidget);
  });
}

const _searchIndex = '''
  [
    {"i": 1, "s": "hero-show-1", "n": "Hero Show", "e": 1}
  ]
''';
