import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/media_quality_manager.dart';
import 'package:tako_play/helpers/network_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/helpers/update_manager.dart';
import 'package:tako_play/helpers/webview_manager.dart';
import 'package:tako_play/main.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/widgets/popular_anime_card.dart';

void initializeIntegrationTests() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> launchFixtureApp(
  WidgetTester tester, {
  bool failFirstDetailRequest = false,
  bool failEpisodeEmbedRequest = false,
}) async {
  Get.reset();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(
    MyApp(
      initialBinding: FixtureBinding(
        failFirstDetailRequest: failFirstDetailRequest,
        failEpisodeEmbedRequest: failEpisodeEmbedRequest,
      ),
    ),
  );
  await waitForUi(tester);
}

Future<void> waitForUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await waitForUi(tester);
}

Future<void> openFixtureDetails(WidgetTester tester) async {
  await tapAndWait(tester, find.byType(PopularAnimeCard).first);
  // The native route transition and the two fixture-backed detail requests
  // complete asynchronously on device. Wait for the loaded detail state, not
  // merely the route shell, before a flow scrolls or interacts with it.
  await tester.pump(const Duration(seconds: 2));
}

Future<void> returnToMain(WidgetTester tester) async {
  final backButton = find
      .descendant(
        // Previous routes remain mounted during Cupertino transitions. The
        // last app bar belongs to the active route.
        of: find.byType(AppBar).last,
        matching: find.byType(IconButton),
      )
      .first;
  await tapAndWait(tester, backButton);
  await tester.pump(const Duration(seconds: 2));
}

Future<void> scrollDetailUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find.byType(Scrollable).last,
  );
  await waitForUi(tester);
}

class FixtureBinding extends Bindings {
  FixtureBinding({
    required this.failFirstDetailRequest,
    required this.failEpisodeEmbedRequest,
  });

  final bool failFirstDetailRequest;
  final bool failEpisodeEmbedRequest;

  @override
  void dependencies() {
    final catalog = _FixtureCatalog(
      failFirstDetailRequest: failFirstDetailRequest,
      failEpisodeEmbedRequest: failEpisodeEmbedRequest,
    );
    final requestService = RequestService(client: MockClient(catalog.handle));

    Get.put<RequestService>(requestService, permanent: true);
    Get.put<RecentWatchManager>(
      RecentWatchManager(database: _MemoryRecentStore()),
      permanent: true,
    );
    Get.put<WebViewManager>(WebViewManager(), permanent: true);
    Get.put<MediaQualityManager>(MediaQualityManager(), permanent: true);
    Get.put<NetworkManager>(_OnlineNetworkManager(), permanent: true);
    Get.put<BookMarkManager>(
      BookMarkManager(database: _MemoryBookmarkStore()),
      permanent: true,
    );
    Get.put<UpdateManager>(
      UpdateManager(requestService: requestService),
      permanent: true,
    );
  }
}

class _OnlineNetworkManager extends NetworkManager {
  _OnlineNetworkManager() : super(autoStart: false);

  @override
  bool get isOnline => true;
}

class _MemoryBookmarkStore implements BookmarkStore {
  final _items = <BookMark>[];

  @override
  Future<int> delete(String id) async {
    final before = _items.length;
    _items.removeWhere((item) => item.id == id);
    return before - _items.length;
  }

  @override
  Future<List<BookMark>> getAllBookMarks() async => List.of(_items);

  @override
  Future<void> insert(BookMark bookMark) async {
    _items.removeWhere((item) => item.id == bookMark.id);
    _items.add(bookMark);
  }
}

class _MemoryRecentStore implements RecentAnimeStore {
  final _items = <RecentAnime>[];

  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => List.of(_items);

  @override
  Future<void> insert(RecentAnime anime) async {
    _items.removeWhere((item) => item.id == anime.id);
    _items.add(anime);
  }

  @override
  Future<int> remove(String id) async {
    final before = _items.length;
    _items.removeWhere((item) => item.id == id);
    return before - _items.length;
  }

  @override
  Future<int> removeAll() async {
    final count = _items.length;
    _items.clear();
    return count;
  }
}

class _FixtureCatalog {
  _FixtureCatalog({
    required this.failFirstDetailRequest,
    required this.failEpisodeEmbedRequest,
  });

  bool failFirstDetailRequest;
  final bool failEpisodeEmbedRequest;

  Future<http.Response> handle(http.BaseRequest request) async {
    final uri = request.url;
    if (uri.host == 'api.github.com') {
      return http.Response('{"tag_name":"v1.7.0","assets":[]}', 200);
    }

    if (request.method == 'POST' && uri.path == '/wp-admin/admin-ajax.php') {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': '''
            <li><a href="/test-hero-episode-1"><span class="name">EP 1</span></a></li>
            <li><a href="/test-hero-episode-2"><span class="name">EP 2</span></a></li>
          ''',
        }),
        200,
      );
    }

    if (uri.path == '/category/test-hero') {
      if (failFirstDetailRequest) {
        failFirstDetailRequest = false;
        return http.Response('temporarily unavailable', 503);
      }
      return http.Response(_detailMarkup, 200);
    }
    if (uri.path == '/movie/test-movie') {
      return http.Response(_movieDetailMarkup, 200);
    }
    if (uri.path == '/test-hero-episode-1' ||
        uri.path == '/test-hero-episode-2') {
      if (failEpisodeEmbedRequest) {
        return http.Response('player unavailable', 503);
      }
      return http.Response(_episodeMarkup, 200);
    }
    if (uri.path == '/popular/' ||
        (uri.path == '/' && uri.queryParameters.containsKey('s')) ||
        uri.path == '/genres/action/') {
      return http.Response(_catalogMarkup, 200);
    }
    if (uri.path == '/genres/action/page/2/') {
      return http.Response('<ul class="items"></ul>', 200);
    }
    if (uri.path == '/movies/') {
      return http.Response(_movieListingMarkup, 200);
    }
    if (uri.path == '/') {
      return http.Response(_catalogMarkup, 200);
    }
    return http.Response('not found', 404);
  }

  static const _catalogMarkup = '''
    <ul class="items">
      <li>
        <div class="img"></div>
        <p class="name"><a href="/category/test-hero">Ace</a></p>
        <p class="episode">EP 2</p>
        <p class="released">Released: 2026</p>
      </li>
    </ul>
  ''';

  static const _detailMarkup = '''
    <div class="anime_info_body_bg">
      <p class="description">A deterministic fixture synopsis.</p>
      <p class="type">Genres: <a href="/genres/action/">Action</a></p>
      <p class="type">Released: 2026</p>
      <p class="type">Status: Completed</p>
    </div>
    <input id="movie_id" value="fixture-hero">
    <script>const episodeData = { nonce: 'fixture-nonce' };</script>
    <a data-range-start="1" data-range-end="2">1-2</a>
  ''';

  static const _movieListingMarkup = '''
    <ul class="listing">
      <li><a href="/movie/test-movie">Fixture Movie</a></li>
    </ul>
  ''';

  static const _movieDetailMarkup = '''
    <div class="anime_info_body_bg"></div>
  ''';

  static const _episodeMarkup = '''
    <div class="anime_muti_link">
      <a data-video="&lt;iframe src=&quot;https://example.com/player&quot;&gt;&lt;/iframe&gt;">Fixture server</a>
    </div>
  ''';
}
