import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';

void main() {
  late DatabaseFactory factory;
  late Directory directory;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    factory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('tako_play_test_');
  });
  tearDown(() async => directory.delete(recursive: true));

  test('bookmark database migrates legacy duplicates and upserts safely',
      () async {
    final path = '${directory.path}/bookmarks.db';
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE Bookmark(
            id TEXT NOT NULL, name TEXT NOT NULL, imageUrl TEXT NOT NULL,
            animeUrl TEXT NOT NULL)
        '''),
      ),
    );
    await legacy.insert('Bookmark', {
      'id': 'show-1',
      'name': 'Old title',
      'imageUrl': 'old.jpg',
      'animeUrl': '/old',
    });
    await legacy.insert('Bookmark', {
      'id': 'show-1',
      'name': 'New title',
      'imageUrl': 'new.jpg',
      'animeUrl': '/new',
    });
    await legacy.close();

    final store = BookMarksDatabase.withDatabaseFactory(
      databaseFactory: factory,
      databasePath: path,
    );
    expect((await store.getAllBookMarks()).single.name, 'New title');

    await store.insert(BookMark(
      id: 'show-1',
      name: 'Replacement',
      imageUrl: 'replacement.jpg',
      animeUrl: '/replacement',
    ));
    final saved = await store.getAllBookMarks();
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Replacement');
    await store.close();
  });

  test('recent database migrates legacy duplicates and replaces an episode',
      () async {
    final path = '${directory.path}/recent.db';
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE RecentAnime(
            id TEXT NOT NULL, name TEXT NOT NULL, epUrl TEXT NOT NULL,
            currentEp TEXT NOT NULL, imageUrl TEXT NOT NULL)
        '''),
      ),
    );
    for (final episode in ['Episode 1', 'Episode 2']) {
      await legacy.insert('RecentAnime', {
        'id': 'show-1',
        'name': 'Title',
        'epUrl': '/episode',
        'currentEp': episode,
        'imageUrl': 'poster.jpg',
      });
    }
    await legacy.close();

    final store = RecentWatchAnimeDatabase.withDatabaseFactory(
      databaseFactory: factory,
      databasePath: path,
    );
    expect((await store.getAllRecentAnime()).single.currentEp, 'Episode 2');

    await store.insert(RecentAnime(
      id: 'show-1',
      name: 'Title',
      epUrl: '/episode-3',
      currentEp: 'Episode 3',
      imageUrl: 'poster.jpg',
    ));
    final saved = await store.getAllRecentAnime();
    expect(saved, hasLength(1));
    expect(saved.single.currentEp, 'Episode 3');
    await store.close();
  });

  test('bookmark database creates, orders, and deletes fresh records',
      () async {
    final store = BookMarksDatabase.withDatabaseFactory(
      databaseFactory: factory,
      databasePath: '${directory.path}/fresh-bookmarks.db',
    );
    await store.insert(BookMark(
      id: 'one',
      name: 'One',
      imageUrl: '',
      animeUrl: '/one',
    ));
    await store.insert(BookMark(
      id: 'two',
      name: 'Two',
      imageUrl: '',
      animeUrl: '/two',
    ));

    expect(
        (await store.getAllBookMarks()).map((item) => item.id), ['one', 'two']);
    expect(await store.delete('one'), 1);
    expect(await store.delete('missing'), 0);
    expect((await store.getAllBookMarks()).single.id, 'two');
    await store.close();
  });

  test('recent database creates, lists, removes, and clears fresh records',
      () async {
    final store = RecentWatchAnimeDatabase.withDatabaseFactory(
      databaseFactory: factory,
      databasePath: '${directory.path}/fresh-recent.db',
    );
    for (final id in ['one', 'two']) {
      await store.insert(RecentAnime(
        id: id,
        name: id,
        epUrl: '/$id',
        currentEp: 'Episode 1',
        imageUrl: '',
      ));
    }

    expect(await store.remove('one'), 1);
    expect((await store.getAllRecentAnime()).single.id, 'two');
    expect(await store.removeAll(), 1);
    expect(await store.getAllRecentAnime(), isEmpty);
    await store.close();
  });
}
