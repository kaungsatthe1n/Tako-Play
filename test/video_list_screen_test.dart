import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/screens/video_list_screen.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/utils/routes.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('shows an episode empty state after a successful detail load',
      (tester) async {
    _registerManagers();
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_detailsMarkup, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenDetails()));

    await tester.tap(find.text('Open details'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Episodes'), findsOneWidget);
    expect(find.text('Episodes coming soon'), findsOneWidget);
  });

  testWidgets('shows a retry action when details cannot be loaded',
      (tester) async {
    _registerManagers();
    Get.put(RequestService(
      client: MockClient((_) async => http.Response('gone', 410)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenDetails()));

    await tester.tap(find.text('Open details'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('We could not load the episode list.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('keeps its hero data when route arguments clear during a pop',
      (tester) async {
    _registerManagers();
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_detailsMarkup, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenDetails()));

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    // GetX updates this global value while routes transition. Rebuild the
    // detail page with no global arguments, as can happen during an iOS swipe
    // back from the WebView player.
    Get.routing.args = null;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'show-1',
      ),
      findsOneWidget,
    );
  });

  testWidgets('pages a long episode list, saves, and records playback',
      (tester) async {
    final bookmarks = BookMarkManager(database: _BookmarkStore());
    final recents = RecentWatchManager(database: _RecentStore());
    Get.put(bookmarks);
    Get.put(recents);
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_sourceDetailsMarkup, 200)),
    ));
    await tester.pumpWidget(GetMaterialApp(
      home: const _OpenDetails(),
      getPages: [
        GetPage(
          name: Routes.mediaFetchScreen,
          page: () => const Scaffold(body: Text('Media fetch')),
        ),
      ],
    ));

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.text('1 - 50'), findsOneWidget);
    expect(find.text('51 - 51'), findsOneWidget);

    final bookmarkButton = find.byIcon(Icons.bookmark_border_rounded);
    await tester.ensureVisible(bookmarkButton);
    await tester.tap(bookmarkButton);
    await tester.pump();
    expect(bookmarks.ids, ['test-title']);
    Get.closeAllSnackbars();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('1 - 50'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('51 - 51'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('51'));
    await tester.pumpAndSettle();
    expect(find.text('Media fetch'), findsOneWidget);
    expect(recents.animeList.single.currentEp, 'Episode 51');
  });

  testWidgets('animates episode tiles only after changing the range',
      (tester) async {
    _registerManagers();
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_sourceDetailsMarkup, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenDetails()));
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final tileAnimations = find.byWidgetPredicate(
      (widget) => widget is TweenAnimationBuilder<double>,
    );
    expect(tileAnimations, findsNothing);

    await tester.tap(find.text('51 - 51'));
    await tester.pump();
    expect(tileAnimations, findsWidgets);

    await tester.tap(find.text('1 - 50'));
    await tester.pump();
    expect(tileAnimations, findsWidgets);

    await tester.pump(const Duration(milliseconds: 501));
    expect(tileAnimations, findsNothing);
  });

  testWidgets('retries a failed detail request', (tester) async {
    _registerManagers();
    var requests = 0;
    Get.put(RequestService(
      client: MockClient((_) async {
        requests++;
        return http.Response(
          requests == 1 ? 'gone' : _detailsMarkup,
          requests == 1 ? 410 : 200,
        );
      }),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenDetails()));

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Episodes coming soon'), findsOneWidget);
    expect(requests, 2);
  });
}

void _registerManagers() {
  Get.put(BookMarkManager(database: _BookmarkStore()));
  Get.put(RecentWatchManager(database: _RecentStore()));
}

class _OpenDetails extends StatelessWidget {
  const _OpenDetails();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const VideoListScreen(),
              arguments: {
                'anime': Anime(
                  id: 'show-1',
                  name: 'Test title',
                  imageUrl: 'https://example.com/poster.jpg',
                  animeUrl: 'https://gogoanime9.ro/anime/test-title',
                ),
              },
            ),
            child: const Text('Open details'),
          ),
        ),
      );
}

class _BookmarkStore implements BookmarkStore {
  @override
  Future<int> delete(String id) async => 0;

  @override
  Future<List<BookMark>> getAllBookMarks() async => [];

  @override
  Future<void> insert(BookMark bookMark) async {}
}

class _RecentStore implements RecentAnimeStore {
  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => [];

  @override
  Future<void> insert(RecentAnime anime) async {}

  @override
  Future<int> remove(String id) async => 0;

  @override
  Future<int> removeAll() async => 0;
}

const _detailsMarkup = '''
  <div class="anime_info_body_bg">
    <p class="description">A test synopsis.</p>
    <p class="type">Released: 2026</p>
    <p class="type">Status: Completed</p>
  </div>
''';

final _sourceDetailsMarkup = '''
  <section id="info"><p><span class="text-note">Plot Summary:</span> Long test.</p></section>
  <section id="w-episodes">
    ${List.generate(51, (index) => '<button data-n="${index + 1}">EP ${index + 1}</button>').join()}
  </section>
''';
