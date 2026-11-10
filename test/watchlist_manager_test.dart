import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/bookmark_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';

void main() {
  test('bookmark manager persists before exposing additions and removals',
      () async {
    final store = _BookmarkStore();
    final manager = BookMarkManager(database: store);
    final item = BookMark(
      id: 'show-1',
      name: 'Title',
      animeUrl: '/title',
      imageUrl: 'poster.jpg',
    );

    await manager.addToBookMarks(item);
    await manager.addToBookMarks(item);
    expect(store.insertCalls, 1);
    expect(manager.ids, ['show-1']);

    await manager.removeFromBookMarks(item);
    expect(store.items, isEmpty);
    expect(manager.bookMarks, isEmpty);
  });

  test('recent manager keeps the latest watch at the front of the UI',
      () async {
    final store = _RecentStore();
    final manager = RecentWatchManager(database: store);
    final first = _recent('show-1', 'Episode 1');
    final second = _recent('show-2', 'Episode 4');

    await manager.addAnimeToRecent(first);
    await manager.addAnimeToRecent(second);
    await manager.addAnimeToRecent(_recent('show-1', 'Episode 3'));

    expect(manager.animeList.map((anime) => anime.currentEp), [
      'Episode 3',
      'Episode 4',
    ]);
    await manager.removeAllAnime();
    expect(manager.animeList, isEmpty);
    expect(store.removeAllCalls, 1);
  });

  test('managers load their existing stores into UI state', () async {
    final bookmarks = _BookmarkStore()
      ..items.add(BookMark(
        id: 'saved',
        name: 'Saved',
        animeUrl: '/saved',
        imageUrl: '',
      ));
    final recents = _RecentStore()..items.add(_recent('recent', 'Episode 9'));

    final bookmarkManager = BookMarkManager(database: bookmarks);
    final recentManager = RecentWatchManager(database: recents);
    await bookmarkManager.loadBookMarksFromDatabase();
    await recentManager.loadRecentAnimeFromDatabase();

    expect(bookmarkManager.ids, ['saved']);
    expect(recentManager.animeList.single.currentEp, 'Episode 9');
    await recentManager.removeAnime('recent');
    expect(recentManager.animeList, isEmpty);
  });
}

RecentAnime _recent(String id, String episode) => RecentAnime(
      id: id,
      name: 'Title',
      epUrl: '/$id/$episode',
      currentEp: episode,
      imageUrl: 'poster.jpg',
    );

class _BookmarkStore implements BookmarkStore {
  final items = <BookMark>[];
  var insertCalls = 0;

  @override
  Future<void> insert(BookMark item) async {
    insertCalls++;
    items.removeWhere((saved) => saved.id == item.id);
    items.add(item);
  }

  @override
  Future<int> delete(String id) async {
    final before = items.length;
    items.removeWhere((item) => item.id == id);
    return before - items.length;
  }

  @override
  Future<List<BookMark>> getAllBookMarks() async => List.of(items);
}

class _RecentStore implements RecentAnimeStore {
  final items = <RecentAnime>[];
  var removeAllCalls = 0;

  @override
  Future<void> insert(RecentAnime item) async {
    items.removeWhere((saved) => saved.id == item.id);
    items.add(item);
  }

  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => List.of(items);

  @override
  Future<int> remove(String id) async {
    final before = items.length;
    items.removeWhere((item) => item.id == id);
    return before - items.length;
  }

  @override
  Future<int> removeAll() async {
    removeAllCalls++;
    final count = items.length;
    items.clear();
    return count;
  }
}
