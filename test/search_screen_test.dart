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
}

const _searchIndex = '''
  [
    {"i": 1, "s": "hero-show-1", "n": "Hero Show", "e": 1}
  ]
''';
