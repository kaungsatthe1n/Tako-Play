import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/screens/bookmarks_screen.dart';
import 'package:tako_play/screens/recent_list_screen.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('saved screen renders a bookmarked title', (tester) async {
    final manager = BookMarkManager(database: _Bookmarks());
    await manager.addToBookMarks(BookMark(
      id: 'saved-1',
      name: 'Saved show',
      animeUrl: '/watch/saved-1',
      imageUrl: '',
    ));
    Get.put(manager);

    await tester.pumpWidget(const GetMaterialApp(home: BookMarksScreen()));
    await tester.pumpAndSettle();
    expect(find.text('SAVED TITLE'), findsOneWidget);
    expect(find.text('Saved show'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from Saved'));
    await tester.pump();
    expect(manager.bookMarks, isEmpty);
    Get.closeAllSnackbars();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('recent screen renders a watched title', (tester) async {
    final manager = RecentWatchManager(database: _Recents());
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
    expect(find.text('Pick up where you left off'), findsOneWidget);
    expect(find.text('Recent show'), findsOneWidget);
  });
}

class _Bookmarks implements BookmarkStore {
  final items = <BookMark>[];
  @override
  Future<int> delete(String id) async {
    final count = items.where((item) => item.id == id).length;
    items.removeWhere((item) => item.id == id);
    return count;
  }

  @override
  Future<List<BookMark>> getAllBookMarks() async => List.of(items);
  @override
  Future<void> insert(BookMark item) async {
    items.removeWhere((saved) => saved.id == item.id);
    items.add(item);
  }
}

class _Recents implements RecentAnimeStore {
  final items = <RecentAnime>[];
  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => List.of(items);
  @override
  Future<void> insert(RecentAnime item) async {
    items.removeWhere((saved) => saved.id == item.id);
    items.add(item);
  }

  @override
  Future<int> remove(String id) async {
    final count = items.where((item) => item.id == id).length;
    items.removeWhere((item) => item.id == id);
    return count;
  }

  @override
  Future<int> removeAll() async => 0;
}
