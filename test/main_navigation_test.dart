import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/network_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/helpers/update_manager.dart';
import 'package:tako_play/helpers/webview_manager.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/screens/main_screen.dart';
import 'package:tako_play/services/request_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async => Get.reset());

  testWidgets(
      'switches among bottom-navigation pages without rebuilding routes',
      (tester) async {
    Get.put<NetworkManager>(NetworkManager(autoStart: false));
    Get.put(WebViewManager());
    Get.put(BookMarkManager(database: _BookmarkStore()));
    Get.put(RecentWatchManager(database: _RecentStore()));
    final requestService = RequestService(
      client: MockClient(
        (_) async => http.Response('{"tag_name":"v1.6.3","assets":[]}', 200),
      ),
    );
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));

    await tester.pumpWidget(const GetMaterialApp(home: MainScreen()));
    await tester.pump();

    expect(find.text('Discover'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    await tester.pumpAndSettle();
    expect(find.text('My library'), findsOneWidget);
    expect(find.text('Your Saved list is empty'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Continue watching'), findsOneWidget);
    expect(find.text('Nothing in your watchlist yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsOneWidget);
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
