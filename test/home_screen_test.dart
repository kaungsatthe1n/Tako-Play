import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/update_manager.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/screens/home_screen.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/utils/routes.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('renders completed popular, new episode, and movie rails',
      (tester) async {
    Get.put(BookMarkManager(database: _BookmarkStore()));
    final requestService = RequestService(
      client: MockClient((request) async {
        if (request.url.host.contains('github')) {
          return http.Response('{"tag_name":"v1.8.0","assets":[]}', 200);
        }
        final isMovie = request.url.path.contains('/movies');
        return http.Response(
          '''
            <main><section><ul class="grid"><li>
              <a href="/watch/${isMovie ? 'movie' : 'show'}-1/"><img src="/poster.webp"></a>
              <span>${isMovie ? 'Movie' : 'Ep 4'}</span>
              <p><a href="/watch/${isMovie ? 'movie' : 'show'}-1/">${isMovie ? 'Movie night' : 'Featured show'}</a></p>
            </li></ul></section></main>
          ''',
          200,
        );
      }),
    );
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: HomeScreen())),
    );
    expect(find.text('Popular now'), findsOneWidget);
    expect(find.text('New episodes'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Featured show'), findsNWidgets(2));
    expect(find.text('Movie night'), findsOneWidget);
  });

  testWidgets('featured actions save an anime and open the detail screen',
      (tester) async {
    final bookmarks = BookMarkManager(database: _BookmarkStore());
    Get.put(bookmarks);
    final requestService = RequestService(client: MockClient((request) async {
      if (request.url.host.contains('github')) {
        return http.Response('{"tag_name":"v1.8.0","assets":[]}', 200);
      }
      return http.Response('''
        <main><section><ul class="grid"><li>
          <a href="/watch/show-1/"><img src="/poster.webp"></a>
          <p><a href="/watch/show-1/">Featured show</a></p>
        </li></ul></section></main>''', 200);
    }));
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: HomeScreen()),
      getPages: [
        GetPage(
          name: Routes.videoListScreen,
          page: () => const Scaffold(body: Text('Detail destination')),
        ),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded).first);
    await tester.pumpAndSettle();
    expect(bookmarks.ids, contains('1'));
    await tester.tap(find.byIcon(Icons.bookmark).first);
    await tester.pumpAndSettle();
    expect(bookmarks.ids, isEmpty);
    await tester.tap(find.text('Watch now'));
    await tester.pumpAndSettle();
    expect(find.text('Detail destination'), findsOneWidget);
  });

  testWidgets('featured cards show genres and handle unavailable artwork',
      (tester) async {
    Get.put(BookMarkManager(database: _BookmarkStore()));
    final requestService = RequestService(
        client: MockClient((request) async => http.Response(
            request.url.host.contains('github')
                ? '{"tag_name":"v1.8.0","assets":[]}'
                : '',
            200)));
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));
    final featured = AnimeResults(animeList: [
      Anime(id: '1', name: 'No art', genres: [
        Genre(name: 'Action', link: '/action'),
        Genre(name: 'Drama', link: '/drama'),
      ]),
      const Anime(
          id: '2', name: 'Artwork', imageUrl: 'https://example.com/art.jpg'),
    ]);
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
      body: HomeScreen(featuredResults: Future.value(featured)),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Action · Drama'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    final image = tester
        .widget<CachedNetworkImage>(find.byType(CachedNetworkImage).first);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => image.errorWidget!(
                context, image.imageUrl, StateError('image failed')))));
    expect(find.byType(ColoredBox), findsWidgets);
  });

  testWidgets('genre and catalog links open the selected destinations',
      (tester) async {
    Get.put(BookMarkManager(database: _BookmarkStore()));
    final requestService = RequestService(client: MockClient((request) async {
      if (request.url.host.contains('github')) {
        return http.Response('{"tag_name":"v1.8.0","assets":[]}', 200);
      }
      final cards = List.generate(
        8,
        (i) => '<li><a href="/watch/show-$i/"><img src="/poster.webp"></a>'
            '<p><a href="/watch/show-$i/">Show $i</a></p></li>',
      ).join();
      return http.Response(
          '<main><section><ul class="grid">$cards</ul></section></main>', 200);
    }));
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: HomeScreen()),
      getPages: [
        GetPage(
            name: Routes.genreScreen,
            page: () => const Scaffold(body: Text('Genre destination'))),
        GetPage(
            name: Routes.catalogGridScreen,
            page: () => const Scaffold(body: Text('Catalog destination'))),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(find.text('Genre destination'), findsOneWidget);
    expect((Get.arguments as Genre).name, 'Action');
    Get.back();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Show 1'), findsWidgets);
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();
    expect(find.text('Catalog destination'), findsOneWidget);
    expect(Get.arguments['title'], 'Popular now');
    Get.back();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Movies'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final moviesTitle = find.text('Movies');
    final moviesRow =
        find.ancestor(of: moviesTitle, matching: find.byType(Row)).first;
    await tester
        .tap(find.descendant(of: moviesRow, matching: find.text('See all')));
    await tester.pumpAndSettle();
    expect(Get.arguments['title'], 'Movies');
  });
}

class _BookmarkStore implements BookmarkStore {
  @override
  Future<int> delete(String id) async => 0;

  @override
  Future<List<BookMark>> getAllBookMarks() async => [];

  @override
  Future<void> insert(BookMark bookMark) async {}
}
