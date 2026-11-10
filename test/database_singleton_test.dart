import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tako_play/database/bookmark_database.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/models/bookmark.dart';
import 'package:tako_play/models/recent_anime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('singleton databases open through the platform defaults', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory =
        await Directory.systemTemp.createTemp('tako_play_singleton_');
    addTearDown(() => directory.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return directory.path;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final bookmarks = BookMarksDatabase.instance;
    await bookmarks.insert(BookMark(
      id: 'singleton-show',
      name: 'Singleton title',
      imageUrl: '',
      animeUrl: '/singleton',
    ));
    expect(
      (await bookmarks.getAllBookMarks()).map((item) => item.id),
      contains('singleton-show'),
    );
    expect(await bookmarks.delete('singleton-show'), 1);
    await bookmarks.close();

    final recents = RecentWatchAnimeDatabase.instance;
    await recents.insert(RecentAnime(
      id: 'singleton-recent',
      name: 'Singleton recent',
      epUrl: '/recent',
      currentEp: 'Episode 1',
      imageUrl: '',
    ));
    expect(
      (await recents.getAllRecentAnime()).map((item) => item.id),
      contains('singleton-recent'),
    );
    expect(await recents.remove('singleton-recent'), 1);
    await recents.close();
  });
}
