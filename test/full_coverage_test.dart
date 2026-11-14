import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/bindings/managers_binding.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/network_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/helpers/update_manager.dart';
import 'package:tako_play/helpers/webview_manager.dart';
import 'package:tako_play/main.dart' as app;
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/playback_context.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/screens/about_app_screen.dart';
import 'package:tako_play/screens/bookmarks_screen.dart';
import 'package:tako_play/screens/genre_screen.dart';
import 'package:tako_play/screens/genre_selection_screen.dart';
import 'package:tako_play/screens/home_screen.dart';
import 'package:tako_play/screens/main_screen.dart';
import 'package:tako_play/screens/media_fetch_screen.dart';
import 'package:tako_play/screens/no_internet_screen.dart';
import 'package:tako_play/screens/recent_list_screen.dart';
import 'package:tako_play/screens/search_screen.dart';
import 'package:tako_play/screens/settings_screen.dart';
import 'package:tako_play/screens/video_list_screen.dart';
import 'package:tako_play/screens/video_player_screen.dart';
import 'package:tako_play/screens/webview_screen.dart';
import 'package:tako_play/services/anime_service.dart';
import 'package:tako_play/services/playback_service.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/utils/constants.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/utils/tako_route.dart';
import 'package:tako_play/widgets/anime_drawer.dart';
import 'package:tako_play/widgets/cache_image_with_cachemanager.dart';
import 'package:tako_play/widgets/hls_extractor_web_view.dart';
import 'package:tako_play/widgets/movie_card.dart';
import 'package:tako_play/widgets/popular_anime_card.dart';
import 'package:tako_play/widgets/recent_anime_card.dart';
import 'package:tako_play/widgets/recently_added_anime_card.dart';
import 'package:tako_play/widgets/searched_result_anime_card.dart';
import 'package:tako_play/widgets/tako_loading_indicator.dart';
import 'package:tako_play/widgets/tako_pressable_card.dart';
import 'package:tako_play/widgets/tako_scaffold.dart';
import 'package:tako_play/widgets/update_alert_dialog.dart';
import 'package:tako_play/widgets/website_error_widget.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart'
    hide X509Certificate;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  late _FakeUrlLauncherPlatform urlLauncher;

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    urlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = urlLauncher;
    WebViewPlatform.instance = _FakeWebViewPlatform();
    _FakeWebViewController.last = null;
  });
  tearDown(() async => Get.reset());

  test('route names keep their published values', () {
    expect(Routes.mainScreen, '/');
    expect(Routes.homeScreen, '/home');
    expect(Routes.searchScreen, '/search');
    expect(Routes.videoListScreen, '/video-list');
    expect(Routes.aboutAppScreen, '/about-app');
    expect(Routes.mediaFetchScreen, '/media-fetch');
    expect(Routes.recentListScreen, '/recent-watch-list');
    expect(Routes.bookMarkScreen, '/bookmarks');
    expect(Routes.noInternetScreen, '/no-internet-screen');
    expect(Routes.webViewScreen, '/web-view');
    expect(Routes.videoPlayerScreen, '/video-player');
    expect(Routes.settingsScreen, '/settings');
    expect(Routes.genreScreen, '/genre');
    expect(Routes.genreSelectionScreen, '/genreSelection');
  });

  test('media file pattern matches HLS URLs only', () {
    expect(
      mediaFileRegExp.hasMatch('https://cdn.example.com/video/master.m3u8'),
      isTrue,
    );
    expect(
      mediaFileRegExp.hasMatch('http://cdn.example.com/video/master.m3u8'),
      isFalse,
    );
    expect(resolutionRegExp.hasMatch('720P'), isTrue);
  });

  test('every registered route builds its screen widget', () {
    final builders = {for (final page in TakoRoute.pages) page.name: page.page};
    expect(
        builders.keys,
        containsAll(<String>[
          Routes.mainScreen,
          Routes.homeScreen,
          Routes.aboutAppScreen,
          Routes.searchScreen,
          Routes.recentListScreen,
          Routes.videoListScreen,
          Routes.mediaFetchScreen,
          Routes.videoPlayerScreen,
          Routes.webViewScreen,
          Routes.noInternetScreen,
          Routes.settingsScreen,
          Routes.genreScreen,
          Routes.genreSelectionScreen,
        ]));
    expect(builders[Routes.mainScreen]!(), isA<MainScreen>());
    expect(builders[Routes.homeScreen]!(), isA<HomeScreen>());
    expect(builders[Routes.recentListScreen]!(), isA<RecentListScreen>());
    expect(builders[Routes.videoListScreen]!(), isA<VideoListScreen>());
    expect(builders[Routes.mediaFetchScreen]!(), isA<MediaFetchScreen>());
    expect(builders[Routes.genreScreen]!(), isA<GenreScreen>());
    expect(builders[Routes.aboutAppScreen]!(), isA<AboutAppScreen>());
    expect(builders[Routes.noInternetScreen]!(), isA<NoInternetScreen>());
    expect(builders[Routes.settingsScreen]!(), isA<SettingScreen>());
    expect(
        builders[Routes.genreSelectionScreen]!(), isA<GenreSelectionScreen>());
    expect(builders[Routes.videoPlayerScreen]!(), isA<VideoPlayerScreen>());
    expect(builders[Routes.webViewScreen]!(), isA<WebViewScreen>());
    expect(builders[Routes.searchScreen]!(), isA<SearchScreen>());
  });

  test('manager binding registers every permanent manager', () {
    ManagerBinding().dependencies();

    expect(Get.isRegistered<RequestService>(), isTrue);
    expect(Get.isRegistered<RecentWatchManager>(), isTrue);
    expect(Get.isRegistered<WebViewManager>(), isTrue);
    expect(Get.isRegistered<NetworkManager>(), isTrue);
    expect(Get.isRegistered<BookMarkManager>(), isTrue);
    expect(Get.isRegistered<UpdateManager>(), isTrue);
  });

  test('managers fall back to their singleton stores', () {
    expect(BookMarkManager(), isA<BookMarkManager>());
    expect(RecentWatchManager(), isA<RecentWatchManager>());
  });

  testWidgets('app entry point builds the routed shell', (tester) async {
    await app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(app.MyApp), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('about screen opens the source and contact links',
      (tester) async {
    Get.put(UpdateManager(
      requestService: RequestService(
        client: MockClient((_) async =>
            http.Response('{"tag_name":"v1.8.0","assets":[]}', 200)),
      ),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: AboutAppScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Kaung Satt Hein'), findsOneWidget);

    await tester.tap(find.text('Source Code'));
    await tester.pump();
    await tester.tap(find.text('Contact Developer'));
    await tester.pump();

    expect(urlLauncher.launched, contains(takoPlay));
    expect(urlLauncher.launched, anyElement(startsWith('mailto:')));
  });

  testWidgets('about screen reports when no update is available',
      (tester) async {
    Get.put(UpdateManager(
      requestService: RequestService(
        client: MockClient((_) async =>
            http.Response('{"tag_name":"v1.8.0","assets":[]}', 200)),
      ),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: AboutAppScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check For Update '));
    await tester.pumpAndSettle();

    expect(find.text('No update is available right now.'), findsOneWidget);
  });

  testWidgets('about screen offers a published update', (tester) async {
    Get.put(UpdateManager(
      requestService: RequestService(
        client: MockClient((_) async => http.Response(
            '{"tag_name":"v9.9.9","assets":[{"browser_download_url":"https://example.com/app.apk"}]}',
            200)),
      ),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: AboutAppScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check For Update '));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateAlertDialog), findsOneWidget);
  });

  testWidgets('about screen surfaces a failed link launch', (tester) async {
    urlLauncher.result = false;
    Get.put(UpdateManager(
      requestService: RequestService(
        client: MockClient((_) async =>
            http.Response('{"tag_name":"v1.8.0","assets":[]}', 200)),
      ),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: AboutAppScreen()));
    await tester.pumpAndSettle();

    Object? caught;
    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.text('Source Code'));
      await tester.pump();
      await tester.pump();
    }, (error, stackTrace) => caught = error);

    expect(caught, isA<Exception>());
    expect(caught.toString(), contains('Could not launch'));
  });

  testWidgets('settings switch persists the browser player choice',
      (tester) async {
    final manager = WebViewManager();
    Get.put(manager);
    await tester.pumpWidget(const GetMaterialApp(home: SettingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Use browser player'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(manager.isWebView, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('isWebViewPlayerType'),
      isTrue,
    );
  });

  testWidgets('no internet screen retries the connection check',
      (tester) async {
    final manager = _CountingNetworkManager();
    Get.put<NetworkManager>(manager);
    await tester.pumpWidget(const MaterialApp(home: NoInternetScreen()));
    await tester.pump();

    expect(find.text('There is no internet connection'), findsOneWidget);
    await tester.tap(find.text('Try Again'));
    await tester.pump();

    expect(manager.checkCalls, 1);
  });

  testWidgets('genre selection opens the tapped genre', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const GenreSelectionScreen(),
        getPages: [
          GetPage(
            name: Routes.genreScreen,
            page: () => const Scaffold(body: Text('Genre destination')),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Action'), findsOneWidget);
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();

    expect(find.text('Genre destination'), findsOneWidget);
  });

  testWidgets('website error widget retries and shows its message',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebsiteErrorWidget(
            message: 'Catalog unavailable',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Catalog unavailable'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WebsiteErrorWidget()),
      ),
    );
    await tester.pump();
    expect(find.text('We could not load this right now.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('media fetch hands off to the browser player when preferred',
      (tester) async {
    SharedPreferences.setMockInitialValues({'isWebViewPlayerType': true});
    Get.put(WebViewManager());
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_embedMarkup, 200)),
    ));
    await tester.pumpWidget(
      GetMaterialApp(
        home: const _LaunchMedia(),
        getPages: [
          GetPage(
            name: Routes.webViewScreen,
            page: () => const Scaffold(body: Text('Browser destination')),
          ),
          GetPage(
            name: Routes.videoPlayerScreen,
            page: () => const Scaffold(body: Text('Player destination')),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Open media'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Browser destination'), findsOneWidget);
  });

  testWidgets('media fetch shows a retryable error', (tester) async {
    var requests = 0;
    Get.put(WebViewManager());
    Get.put(RequestService(
      client: MockClient((_) async {
        requests++;
        return http.Response('unavailable', 503);
      }),
    ));
    await tester.pumpWidget(
      GetMaterialApp(
        home: const _LaunchMedia(),
        getPages: [
          GetPage(
            name: Routes.webViewScreen,
            page: () => const Scaffold(body: Text('Browser destination')),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Open media'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Episode can't be fetched"), findsOneWidget);
    final before = requests;
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(requests, greaterThan(before));
    expect(find.text("Episode can't be fetched"), findsOneWidget);
  });

  testWidgets('media fetch hands a resolved source to the native player',
      (tester) async {
    Get.put(WebViewManager());
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_embedMarkup, 200)),
    ));
    await tester.pumpWidget(
      GetMaterialApp(
        home: _LaunchMedia(
          playbackService: PlaybackService(
            resolverUrl: 'https://api.example.com/playback',
            client: MockClient((_) async => http.Response(
                jsonEncode({
                  'url': 'https://cdn.example.com/master.m3u8',
                  'headers': <String, String>{},
                  'subtitles': <dynamic>[],
                }),
                200)),
          ),
        ),
        getPages: [
          GetPage(
            name: Routes.videoPlayerScreen,
            page: () => const Scaffold(body: Text('Player destination')),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Open media'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Player destination'), findsOneWidget);
  });

  {
    testWidgets('media fetch extracts a dynamic player source', (tester) async {
      Get.put(WebViewManager());
      Get.put(RequestService(
        client: MockClient((_) async => http.Response(_embedMarkup, 200)),
      ));
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _LaunchMedia(),
          getPages: [
            GetPage(
              name: Routes.videoPlayerScreen,
              page: () => const Scaffold(body: Text('Player destination')),
            ),
            GetPage(
              name: Routes.webViewScreen,
              page: () => const Scaffold(body: Text('Browser destination')),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open media'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      final controller = _FakeWebViewController.last;
      expect(controller, isNotNull);
      controller!.send(jsonEncode({
        'type': 'hls',
        'url': 'https://cdn.example.com/master.m3u8',
        'pageUrl': 'https://player.example/embed',
      }));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Player destination'), findsOneWidget);
    });

    testWidgets('media fetch resolves an embedded HLS source directly',
        (tester) async {
      HttpOverrides.global = _ResolverHttpOverrides(utf8.encode(
        '<html><body><source src="https://cdn.example.com/master.m3u8">'
        '</body></html>',
      ));
      addTearDown(() => HttpOverrides.global = null);
      Get.put(WebViewManager());
      Get.put(RequestService(
        client: MockClient((_) async => http.Response(_embedMarkup, 200)),
      ));
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _LaunchMedia(),
          getPages: [
            GetPage(
              name: Routes.videoPlayerScreen,
              page: () => const Scaffold(body: Text('Player destination')),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open media'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Player destination'), findsOneWidget);
    });
  }

  testWidgets('video player builds a native player for its arguments',
      (tester) async {
    final platform = _FakeBetterPlayerPlatform();
    BetterPlayerPlatform.instance = platform;
    await tester.pumpWidget(
      GetMaterialApp(
        home: const _LaunchVideoPlayer(),
        getPages: const [],
      ),
    );

    await tester.tap(find.text('Open player'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(VideoPlayerScreen), findsOneWidget);
    expect(find.byType(BetterPlayer), findsOneWidget);
    expect(platform.dataSources, isNotEmpty);
    expect(
      platform.dataSources.single.uri,
      'https://cdn.example.com/master.m3u8',
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('native fullscreen overlay switches source and updates history',
      (tester) async {
    await http.runWithClient(() async {
      final platform = _FakeBetterPlayerPlatform();
      BetterPlayerPlatform.instance = platform;
      final history = RecentWatchManager(database: _MemoryRecentStore());
      Get.put(history);
      var loads = 0;
      final queue = PlaybackContext(
          id: 'test',
          name: 'Test series',
          imageUrl: '',
          animeUrl: '/test',
          index: 0,
          episodes: [
            Episode(number: '1', link: '/test#episode=1'),
            Episode(number: '2', link: '/test#episode=2'),
          ]);
      await tester.pumpWidget(GetMaterialApp(
          home: Builder(
              builder: (context) => TextButton(
                  onPressed: () => Get.to(
                          () =>
                              VideoPlayerScreen(nextSourceLoader: (next) async {
                                loads++;
                                expect(next.episode.number, '2');
                                return const PlaybackSource(
                                    url: 'https://cdn.example/next.m3u8',
                                    headers: {
                                      'Referer': 'https://player.example/'
                                    },
                                    subtitles: [
                                      PlaybackSubtitle(
                                          url: 'https://cdn.example/en.vtt',
                                          name: 'English',
                                          headers: {},
                                          selectedByDefault: true,
                                          content:
                                              'WEBVTT\n\n00:00.000 --> 00:01.000\nHello'),
                                    ]);
                              }),
                          arguments: {
                            'url': 'https://cdn.example/current.m3u8',
                            'playbackContext': queue,
                            'endingStart': const Duration(seconds: 1300)
                          }),
                  child: const Text('Open queued player')))));
      await tester.tap(find.text('Open queued player'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final player = tester.widget<BetterPlayer>(find.byType(BetterPlayer));
      final controller = player.controller;
      // Mount the actual configured fullscreen builder above a gesture surface.
      // This verifies the route used by BetterPlayer, not just an isolated card.
      unawaited(Navigator.of(tester.element(find.byType(BetterPlayer))).push(
          MaterialPageRoute<void>(
              builder: (context) =>
                  controller.betterPlayerConfiguration.routePageBuilder!(
                      context,
                      const AlwaysStoppedAnimation(1),
                      const AlwaysStoppedAnimation(0),
                      BetterPlayerControllerProvider(
                          controller: controller,
                          child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => fail(
                                  'Player gestures must not swallow Next taps'),
                              child: const SizedBox.expand()))))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      controller.postEvent(PlayerEvent(PlayerEventType.progress, parameters: {
        'progress': const Duration(seconds: 1301),
        'duration': const Duration(seconds: 1440),
      }));
      await tester.pump();
      expect(find.text('Up next · Episode 2').hitTestable(), findsOneWidget);
      expect(loads, 1);
      expect(platform.dataSources, hasLength(1));
      await tester.tap(find.text('Play next').hitTestable());
      await tester.pump();
      for (var i = 0; i < 30 && history.animeList.isEmpty; i++) {
        // Native initialization and HTTP stream delivery leave the fake timer
        // zone. Drain that work as well as advancing player retry timers.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(platform.dataSources.last.uri, 'https://cdn.example/next.m3u8');
      expect(controller.betterPlayerDataSource!.headers!['Referer'],
          'https://player.example/');
      expect(controller.betterPlayerDataSource!.subtitles!.single.content,
          contains('Hello'));
      expect(history.animeList, isNotEmpty,
          reason:
              'Player state: ${controller.videoPlayerValue}; overlay: ${find.text('Retry next').evaluate().length}');
      expect(history.animeList.single.currentEp, 'Episode 2');
      expect(find.text('Play next'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
        () => MockClient((request) async => http.Response(
            '#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXTINF:10,\nsegment.ts\n#EXT-X-ENDLIST',
            200,
            request: request)));
  });

  testWidgets('poster cards build their image error placeholders',
      (tester) async {
    const anime = Anime(
      id: 'poster-show',
      name: 'Poster title',
      imageUrl: 'https://example.com/poster.jpg',
      animeUrl: 'https://example.com/anime/poster-show',
    );
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 190, child: PopularAnimeCard(anime: anime)),
                SizedBox(height: 160, child: MovieCard(anime: anime)),
                SizedBox(
                    height: 300, child: RecentlyAddedAnimeCard(anime: anime)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final images =
        tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(images, hasLength(3));
    for (final image in images) {
      final context = tester.element(find.byType(CachedNetworkImage).first);
      expect(
        image.errorWidget!(context, image.imageUrl, Exception('offline')),
        isA<ColoredBox>(),
      );
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NetworkImageWithCacheManager(
            imageUrl: 'https://example.com/poster.jpg',
          ),
        ),
      ),
    );
    await tester.pump();
    final cached =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    final built = cached.errorWidget!(
      tester.element(find.byType(CachedNetworkImage)),
      cached.imageUrl,
      Exception('offline'),
    );
    expect(built, isA<Icon>());
    expect((built as Icon).icon, Icons.error_sharp);
  });

  testWidgets('pressable card clears its pressed state on cancel',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TakoPressableCard(
            borderRadius: BorderRadius.circular(12),
            onTap: () => taps++,
            child: const SizedBox(width: 120, height: 80),
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InkWell)));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('loading view centers its indicator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TakoLoadingView(avoidBottomNavigation: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TakoLoadingIndicator), findsOneWidget);
  });

  testWidgets('searched result card opens episode details', (tester) async {
    const anime = Anime(
      id: 'search-show',
      name: 'Search title (Dub)',
      imageUrl: '',
      animeUrl: 'https://example.com/anime/search-show',
    );
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: SearchedResultAnimeCard(anime: anime)),
        getPages: [
          GetPage(
            name: Routes.videoListScreen,
            page: () => const Scaffold(body: Text('Episode details')),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(SearchedResultAnimeCard));
    await tester.pumpAndSettle();

    expect(find.text('Episode details'), findsOneWidget);
  });

  testWidgets('recent card continues an episode through media fetch',
      (tester) async {
    Get.put(RecentWatchManager(database: _MemoryRecentStore()));
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(
          body: RecentAnimeCard(
            id: 'recent-show',
            name: 'Recent title',
            currentEp: 'Episode 3',
            imageUrl: '',
            epUrl: 'https://example.com/watch/recent-episode-3',
          ),
        ),
        getPages: [
          GetPage(
            name: Routes.mediaFetchScreen,
            page: () => const Scaffold(body: Text('Media fetch')),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(RecentAnimeCard));
    await tester.pumpAndSettle();

    expect(find.text('Media fetch'), findsOneWidget);
  });

  testWidgets('update dialog dismisses from its close button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _DialogLauncher()),
    );
    await tester.tap(find.text('Show update'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAlertDialog), findsOneWidget);

    await tester.tap(find.byTooltip('Close update prompt'));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateAlertDialog), findsNothing);
  });

  testWidgets('update dialog opens the download link', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _DialogLauncher()),
    );
    await tester.tap(find.text('Show update'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'View release'));
    await tester.pump();

    expect(urlLauncher.launched, contains('https://example.com/tako-play.apk'));
  });

  testWidgets('update dialog surfaces a failed download launch',
      (tester) async {
    urlLauncher.result = false;
    await tester.pumpWidget(
      const MaterialApp(home: _DialogLauncher()),
    );
    await tester.tap(find.text('Show update'));
    await tester.pumpAndSettle();

    Object? caught;
    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'View release'));
      await tester.pump();
      await tester.pump();
    }, (error, stackTrace) => caught = error);

    expect(caught, isA<Exception>());
    expect(caught.toString(), contains('Could not launch'));
  });

  test('request service maps socket failures to a network error', () async {
    final service = RequestService(
      client: MockClient((_) => throw const SocketException('unreachable')),
    );

    await expectLater(
      service.requestPopularResponse(),
      throwsA(isA<RequestException>().having(
          (error) => error.message, 'message', contains('Could not reach'))),
    );
    service.close();
  });

  test('anime service falls back to the episode label as release date',
      () async {
    final service = RequestService(
      client: MockClient((_) async => http.Response('', 200)),
    );
    final results = await AnimeService(requestService: service).getAnimes(
      Future.value(http.Response('''
        <ul class="items"><li>
          <p class="name"><a href="/category/legacy">Legacy</a></p>
          <p class="episode">EP 5</p>
        </li></ul>
      ''', 200)),
    );

    expect(results.animeList.single.releasedDate, 'EP 5');
    service.close();
  });

  test('anime service uses the listed episode when none is active', () async {
    final service = RequestService(
      client: MockClient((_) async => http.Response('''
        <section id="w-episodes"><button data-n="3">EP 3</button></section>
        <button class="w-server" data-sv="4">Server 4</button>
        <button class="w-lang" data-lang="dub">Dub</button>
        <script>const host = "https://play.gogoanimes.org", token = "abcdefghijklmnopqrstuvwxyz_1234567890-abcdef";</script>
      ''', 200)),
    );

    final players = await AnimeService(requestService: service)
        .fetchIframeEmbeds('https://gogoanimes.org/watch/show-9/');

    expect(players, [
      'https://play.gogoanimes.org/watch#abcdefghijklmnopqrstuvwxyz_1234567890-abcdef.3.4.dub',
    ]);
    service.close();
  });

  test('anime service uses the active episode button', () async {
    final service = RequestService(
      client: MockClient((_) async => http.Response('''
        <section id="w-episodes"><button data-n="5" class="active">EP 5</button></section>
        <button class="w-server" data-sv="2">Server 2</button>
        <button class="w-lang" data-lang="sub">Sub</button>
        <script>const host = "https://play.gogoanimes.org", token = "abcdefghijklmnopqrstuvwxyz_1234567890-abcdef";</script>
      ''', 200)),
    );

    final players = await AnimeService(requestService: service)
        .fetchIframeEmbeds('https://gogoanimes.org/watch/show-9/');

    expect(players, [
      'https://play.gogoanimes.org/watch#abcdefghijklmnopqrstuvwxyz_1234567890-abcdef.5.2.sub',
    ]);
    service.close();
  });

  test('anime service keeps a root catalog URL as its own id', () async {
    final service = RequestService(
      client: MockClient((_) async => http.Response('''
        <section id="info">
          <p><span class="text-note">Released:</span> 2026</p>
        </section>
      ''', 200)),
    );

    final anime = await AnimeService(requestService: service)
        .fetchAnimeDetails('https://gogoanimes.org');

    expect(anime.id, 'https://gogoanimes.org');
    service.close();
  });

  testWidgets('home screen offers a published update on start', (tester) async {
    final requestService = RequestService(
      client: MockClient((request) async {
        if (request.url.host.contains('github')) {
          return http.Response(
            '{"tag_name":"v9.9.9","assets":[{"browser_download_url":"https://example.com/app.apk"}]}',
            200,
          );
        }
        return http.Response('<main></main>', 200);
      }),
    );
    Get.put(BookMarkManager(database: _MemoryBookmarkStore()));
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: HomeScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateAlertDialog), findsOneWidget);
  });

  testWidgets('search error state retries the request', (tester) async {
    var requests = 0;
    Get.put(RequestService(
      client: MockClient((_) async {
        requests++;
        return http.Response('unavailable', 503);
      }),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'hero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
    final before = requests;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(requests, greaterThan(before));
  });

  testWidgets('web view toggle requests landscape from portrait',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(
      const GetMaterialApp(home: _LaunchWebViewScreen()),
    );

    await tester.tap(find.text('Open player'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(WebViewScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Toggle fullscreen orientation'));
    await tester.pump();

    Get.back();
    await tester.pumpAndSettle();
  });

  testWidgets('main screen opens its drawer and search page', (tester) async {
    _registerMainManagers();
    await tester.pumpWidget(
      GetMaterialApp(
        home: const MainScreen(),
        getPages: [
          GetPage(
            name: Routes.searchScreen,
            page: () => const Scaffold(body: Text('Search destination')),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Search destination'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(AnimeDrawer), findsOneWidget);
  });

  testWidgets('drawer opens settings and about pages', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: AnimeDrawer()),
        getPages: [
          GetPage(
            name: Routes.settingsScreen,
            page: () => const Scaffold(body: Text('Settings destination')),
          ),
          GetPage(
            name: Routes.aboutAppScreen,
            page: () => const Scaffold(body: Text('About destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings destination'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();

    await tester.tap(find.text('About TakoPlay'));
    await tester.pumpAndSettle();
    expect(find.text('About destination'), findsOneWidget);
  });

  testWidgets('back scaffold pops its route from the back button',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: _LaunchBackScaffold()),
    );

    await tester.tap(find.text('Open scaffold'));
    await tester.pumpAndSettle();
    expect(find.text('Scaffold body'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Scaffold body'), findsNothing);
  });

  testWidgets('saved list opens episode details for a bookmark',
      (tester) async {
    final manager = BookMarkManager(database: _MemoryBookmarkStore());
    await manager.addToBookMarks(BookMark(
      id: 'saved-1',
      name: 'Saved show',
      animeUrl: '/watch/saved-1',
      imageUrl: '',
    ));
    Get.put(manager);
    await tester.pumpWidget(
      GetMaterialApp(
        home: const BookMarksScreen(),
        getPages: [
          GetPage(
            name: Routes.videoListScreen,
            page: () => const Scaffold(body: Text('Episode details')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved show'));
    await tester.pumpAndSettle();

    expect(find.text('Episode details'), findsOneWidget);
  });

  testWidgets('recent list dismisses a watched title', (tester) async {
    final manager = RecentWatchManager(database: _MemoryRecentStore());
    await manager.addAnimeToRecent(RecentAnime(
      id: 'recent-1',
      name: 'Recent show',
      epUrl: '/watch/recent-1',
      currentEp: 'Episode 2',
      imageUrl: '',
    ));
    Get.put(manager);
    await tester.pumpWidget(const GetMaterialApp(home: RecentListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Recent show'), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(manager.animeList, isEmpty);
  });

  testWidgets('details page removes a saved bookmark', (tester) async {
    _registerMainManagers();
    final bookmarks = Get.find<BookMarkManager>();
    await bookmarks.addToBookMarks(BookMark(
      id: 'show-1',
      name: 'Test title',
      animeUrl: 'https://gogoanime9.ro/anime/test-title',
      imageUrl: 'https://example.com/poster.jpg',
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenDetails()));

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final bookmarkButton = find.byIcon(Icons.bookmark_rounded);
    await tester.ensureVisible(bookmarkButton);
    await tester.tap(bookmarkButton);
    await tester.pump();

    expect(bookmarks.ids, isEmpty);
    expect(find.text('Removed from bookmark successfully!'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('web views use WebKit creation parameters on WebKit platforms',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    _mockWebKitChannels();
    final platform = _WebKitFakePlatform();
    WebViewPlatform.instance = platform;

    await tester.pumpWidget(
      const GetMaterialApp(home: _LaunchWebViewScreen()),
    );
    await tester.tap(find.text('Open player'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(WebViewScreen), findsOneWidget);
    expect(
      platform.lastControllerParams,
      isA<WebKitWebViewControllerCreationParams>(),
    );
    Get.back();
    await tester.pumpAndSettle();

    PlaybackSource? extracted;
    await tester.pumpWidget(
      MaterialApp(
        home: HlsExtractorWebView(
          playerUrl: 'https://player.example/embed',
          referrerUrl: 'https://catalog.example/episode',
          onSourceFound: (source) => extracted = source,
          onFailure: () {},
        ),
      ),
    );
    await tester.pump();

    expect(
      platform.lastControllerParams,
      isA<WebKitWebViewControllerCreationParams>(),
    );
    expect(extracted, isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}

const _embedMarkup = '''
  <div class="anime_muti_link">
    <a data-video="&lt;iframe src='https://player.example/embed'&gt;&lt;/iframe&gt;">HD</a>
  </div>
''';

const _detailsMarkup = '''
  <div class="anime_info_body_bg">
    <p class="description">A test synopsis.</p>
    <p class="type">Released: 2026</p>
    <p class="type">Status: Completed</p>
  </div>
  <input id="movie_id" value="show-1">
''';

void _registerMainManagers() {
  Get.put<NetworkManager>(_CountingNetworkManager());
  Get.put(WebViewManager());
  Get.put(BookMarkManager(database: _MemoryBookmarkStore()));
  Get.put(RecentWatchManager(database: _MemoryRecentStore()));
  final requestService = RequestService(
    client: MockClient((request) async => request.url.host.contains('github')
        ? http.Response('{"tag_name":"v1.8.0","assets":[]}', 200)
        : http.Response(_detailsMarkup, 200)),
  );
  Get.put(requestService);
  Get.put(UpdateManager(requestService: requestService));
}

class _CountingNetworkManager extends NetworkManager {
  _CountingNetworkManager() : super(autoStart: false);

  var checkCalls = 0;

  @override
  Future<void> checkConnection() async => checkCalls++;
}

class _LaunchMedia extends StatelessWidget {
  const _LaunchMedia({this.playbackService});

  final PlaybackService? playbackService;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => MediaFetchScreen(playbackService: playbackService),
              arguments: const {
                'animeUrl': 'https://catalog.example/episode-1'
              },
            ),
            child: const Text('Open media'),
          ),
        ),
      );
}

class _LaunchVideoPlayer extends StatelessWidget {
  const _LaunchVideoPlayer();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const VideoPlayerScreen(),
              arguments: const {
                'url': 'https://cdn.example.com/master.m3u8',
                'headers': {'Referer': 'https://example.com/'},
                'subtitles': [
                  PlaybackSubtitle(
                    url: 'https://cdn.example.com/en.vtt',
                    name: 'English',
                    headers: {'Referer': 'https://example.com/'},
                    selectedByDefault: true,
                  ),
                  PlaybackSubtitle(
                    url: 'https://cdn.example.com/fr.vtt',
                    name: 'French',
                    headers: {},
                  ),
                ],
                'resolutions': {'720P': 'https://cdn.example.com/720.m3u8'},
              },
            ),
            child: const Text('Open player'),
          ),
        ),
      );
}

class _LaunchWebViewScreen extends StatelessWidget {
  const _LaunchWebViewScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const WebViewScreen(),
              arguments: const {
                'mediaUrls': ['https://player.example/embed'],
                'episodeUrl': 'https://catalog.example/episode',
              },
            ),
            child: const Text('Open player'),
          ),
        ),
      );
}

class _LaunchBackScaffold extends StatelessWidget {
  const _LaunchBackScaffold();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const TakoScaffoldWithBackButton(
                appBarTitle: 'Scaffold',
                body: Center(child: Text('Scaffold body')),
              ),
            ),
            child: const Text('Open scaffold'),
          ),
        ),
      );
}

class _OpenDetails extends StatelessWidget {
  const _OpenDetails();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const VideoListScreen(),
              arguments: const {
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

class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const UpdateAlertDialog(
                downloadLink: 'https://example.com/tako-play.apk',
              ),
            ),
            child: const Text('Show update'),
          ),
        ),
      );
}

class _MemoryBookmarkStore implements BookmarkStore {
  final items = <BookMark>[];

  @override
  Future<int> delete(String id) async {
    final before = items.length;
    items.removeWhere((item) => item.id == id);
    return before - items.length;
  }

  @override
  Future<List<BookMark>> getAllBookMarks() async => List.of(items);

  @override
  Future<void> insert(BookMark bookMark) async {
    items.removeWhere((item) => item.id == bookMark.id);
    items.add(bookMark);
  }
}

class _MemoryRecentStore implements RecentAnimeStore {
  final items = <RecentAnime>[];

  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => List.of(items);

  @override
  Future<void> insert(RecentAnime anime) async {
    items.removeWhere((item) => item.id == anime.id);
    items.add(anime);
  }

  @override
  Future<int> remove(String id) async {
    final before = items.length;
    items.removeWhere((item) => item.id == id);
    return before - items.length;
  }

  @override
  Future<int> removeAll() async {
    final count = items.length;
    items.clear();
    return count;
  }
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  var result = true;
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return result;
  }
}

class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
          PlatformWebViewControllerCreationParams params) =>
      _FakeWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _FakeWebViewWidget(params);

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams params) =>
      _FakeCookieManager(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams params) =>
      _FakeNavigationDelegate(params);
}

class _WebKitFakePlatform extends WebKitWebViewPlatform {
  PlatformWebViewControllerCreationParams? lastControllerParams;

  @override
  WebKitWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    lastControllerParams = params;
    return _FakeWebKitController(params);
  }

  @override
  WebKitWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _FakeWebKitWidget(params);

  @override
  WebKitWebViewCookieManager createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams params) =>
      WebKitWebViewCookieManager(params);

  @override
  WebKitNavigationDelegate createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams params) =>
      _FakeWebKitDelegate(params);
}

class _FakeWebKitController extends WebKitWebViewController {
  _FakeWebKitController(super.params);

  JavaScriptChannelParams? channel;
  final loaded = <Uri>[];

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      channel = params;
  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      loaded.add(params.uri);
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
  @override
  Future<void> runJavaScript(String javaScript) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}
}

class _FakeWebKitWidget extends WebKitWebViewWidget {
  _FakeWebKitWidget(super.params);

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakeWebKitDelegate extends WebKitNavigationDelegate {
  _FakeWebKitDelegate(super.params);

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback callback) async {}
  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback callback) async {}
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async {}
  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async {}
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async {}
}

void _mockWebKitChannels() {
  const codec = StandardMessageCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in _webKitChannelNames) {
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.webview_flutter_wkwebview.$name',
      (_) async => codec.encodeMessage(<Object?>[null]),
    );
  }
}

const _webKitChannelNames = <String>[
  'NSObject.addObserver',
  'NSObject.removeObserver',
  'NSObject.pigeon_defaultConstructor',
  'WKWebViewConfiguration.pigeon_defaultConstructor',
  'WKWebViewConfiguration.setMediaTypesRequiringUserActionForPlayback',
  'WKWebViewConfiguration.setAllowsInlineMediaPlayback',
  'WKWebViewConfiguration.setLimitsNavigationsToAppBoundDomains',
  'WKWebViewConfiguration.getUserContentController',
  'WKWebViewConfiguration.getPreferences',
  'WKWebViewConfiguration.getDefaultWebpagePreferences',
  'WKWebViewConfiguration.getWebsiteDataStore',
  'WKUIDelegate.pigeon_defaultConstructor',
  'WKNavigationDelegate.pigeon_defaultConstructor',
  'WKWebView.pigeon_defaultConstructor',
  'UIViewWKWebView.pigeon_defaultConstructor',
  'NSViewWKWebView.pigeon_defaultConstructor',
  'UIViewWKWebView.setUIDelegate',
  'NSViewWKWebView.setUIDelegate',
  'UIViewWKWebView.setNavigationDelegate',
  'NSViewWKWebView.setNavigationDelegate',
  'WKUserContentController.addUserScript',
  'WKUserContentController.addScriptMessageHandler',
  'WKUserScript.pigeon_defaultConstructor',
  'WKScriptMessageHandler.pigeon_defaultConstructor',
  'PigeonInternalInstanceManager.removeStrongReference',
];

class _FakeWebViewController extends PlatformWebViewController {
  _FakeWebViewController(super.params) : super.implementation() {
    last = this;
  }

  static _FakeWebViewController? last;
  final loaded = <Uri>[];
  JavaScriptChannelParams? _channel;
  var released = false;

  void send(String message) =>
      _channel!.onMessageReceived(JavaScriptMessage(message: message));

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      _channel = params;
  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      loaded.add(params.uri);
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async =>
      released = true;
  @override
  Future<void> runJavaScript(String javaScript) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakeCookieManager extends PlatformWebViewCookieManager {
  _FakeCookieManager(super.params) : super.implementation();
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback callback) async {}
  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback callback) async {}
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async {}
  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async {}
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async {}
}

class _FakeBetterPlayerPlatform extends BetterPlayerPlatform {
  final _controllers = <int, StreamController<VideoEvent>>{};
  final dataSources = <DataSource>[];
  var _nextTextureId = 1;

  @override
  Future<int?> create({BufferingConfiguration? bufferingConfiguration}) async {
    final textureId = _nextTextureId++;
    _controllers[textureId] = StreamController<VideoEvent>.broadcast();
    return textureId;
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    dataSources.add(dataSource);
    // Closed by dispose() when the platform player is released.
    // ignore: close_sinks
    final controller = _controllers[textureId];
    if (controller != null && !controller.isClosed) {
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 10),
            size: const Size(1280, 720),
            key: dataSource.key,
          ));
        }
      });
    }
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) =>
      _controllers[textureId]?.stream ?? const Stream.empty();

  @override
  Widget buildView(int? textureId) => const SizedBox.expand();

  @override
  Future<void> dispose(int? textureId) async {
    await _controllers.remove(textureId)?.close();
  }

  @override
  Future<void> play(int? textureId) async {}
  @override
  Future<void> pause(int? textureId) async {}
  @override
  Future<void> setLooping(int? textureId, bool looping) async {}
  @override
  Future<void> setVolume(int? textureId, double volume) async {}
  @override
  Future<void> setSpeed(int? textureId, double speed) async {}
  @override
  Future<void> setTrackParameters(
      int? textureId, int? width, int? height, int? bitrate) async {}
  @override
  Future<void> seekTo(int? textureId, Duration? position) async {}
  @override
  Future<Duration> getPosition(int? textureId) async => Duration.zero;
  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async => null;
  @override
  Future<void> enablePictureInPicture(int? textureId, double? top, double? left,
      double? width, double? height) async {}
  @override
  Future<void> disablePictureInPicture(int? textureId) async {}
  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async => false;
  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {}
  @override
  Future<void> setTextTrack(int? textureId, String? name, int? index) async {}
  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {}
  @override
  Future<void> clearCache() async {}
  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize,
      {void Function(PreCacheProgress progress)? onProgress}) async {}
  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {}
}

class _ResolverHttpOverrides extends HttpOverrides {
  _ResolverHttpOverrides([this._body]);

  final List<int>? _body;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ResolverClient(_body);
}

class _ResolverClient extends Fake implements HttpClient {
  _ResolverClient(this._body);

  final List<int>? _body;

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ResolverRequest(_body);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ResolverRequest(_body);
}

class _ResolverRequest extends Fake implements HttpClientRequest {
  _ResolverRequest(this._body);

  final List<int>? _body;
  final _headers = _ResolverHeaders();

  @override
  HttpHeaders get headers => _headers;
  @override
  set followRedirects(bool value) {}
  @override
  set maxRedirects(int value) {}
  @override
  set contentLength(int value) {}
  @override
  set persistentConnection(bool value) {}
  @override
  void add(List<int> data) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();
  @override
  Future<HttpClientResponse> close() async => _ResolverResponse(_body);
}

class _ResolverHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _ResolverResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ResolverResponse([List<int>? body]) : _body = body ?? _defaultBody;

  static final _defaultBody = utf8.encode(jsonEncode({
    'url': 'https://cdn.example.com/master.m3u8',
    'headers': <String, String>{},
    'subtitles': [
      {'url': 'https://cdn.example.com/en.vtt', 'name': 'English'},
    ],
  }));

  final List<int> _body;

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _body.length;
  @override
  HttpHeaders get headers => _ResolverHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  X509Certificate? get certificate => null;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => const [];
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  Future<Socket> detachSocket() =>
      Future.error(UnsupportedError('detachSocket'));
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      Future.error(UnimplementedError('redirect'));
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(_body).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}
