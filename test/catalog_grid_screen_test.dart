import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/screens/catalog_grid_screen.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/widgets/tako_loading_indicator.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  Future<void> openGrid(WidgetTester tester, String title, List<Anime> items,
      {List<String> excluded = const []}) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: TextButton(
          onPressed: () => Get.to(() => const CatalogGridScreen(), arguments: {
            'title': title,
            'animeList': items,
            'excludedAnimeIds': excluded,
          }),
          child: const Text('Open grid'),
        ),
      ),
    ));
    await tester.tap(find.text('Open grid'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  final items = List.generate(
    12,
    (i) => Anime(id: '$i', name: 'Title $i'),
  );

  testWidgets('shows an empty catalog loading state and returns',
      (tester) async {
    await openGrid(tester, 'New episodes', []);
    expect(find.byType(TakoLoadingIndicator), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Open grid'), findsOneWidget);
  });

  testWidgets('paginates popular titles and skips duplicates and exclusions',
      (tester) async {
    final requested = <String>[];
    Get.put(RequestService(client: MockClient((request) async {
      requested.add(request.url.path);
      return http.Response('''
        <main><section><ul class="grid">
          <li><a href="/watch/item-1/"><img src=""></a><p><a href="/watch/item-1/">Duplicate</a></p></li>
          <li><a href="/watch/item-99/"><img src=""></a><p><a href="/watch/item-99/">Excluded</a></p></li>
          <li><a href="/watch/item-100/"><img src=""></a><p><a href="/watch/item-100/">New item</a></p></li>
        </ul></section></main>''', 200);
    })));
    await openGrid(tester, 'Popular now', items, excluded: ['99']);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(requested, contains('/popular/page/2/'));
    expect(find.text('Excluded'), findsNothing);
    expect(find.text('Duplicate'), findsNothing);
    expect(find.text('New item'), findsOneWidget);
  });

  testWidgets('retries a failed movie pagination request', (tester) async {
    var calls = 0;
    Get.put(RequestService(client: MockClient((request) async {
      calls++;
      expect(request.url.path, '/movies/page/2/');
      return calls == 1
          ? http.Response('error', 503)
          : http.Response(
              '<main><section><ul class="grid"></ul></section></main>', 200);
    })));
    await openGrid(tester, 'Movies', items);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(find.text('Could not load more. Tap to retry'), findsOneWidget);
    await tester.tap(find.text('Could not load more. Tap to retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Could not load more. Tap to retry'), findsNothing);
  });
}
