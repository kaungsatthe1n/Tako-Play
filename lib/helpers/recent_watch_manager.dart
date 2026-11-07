import 'package:get/get.dart';

import '../database/recent_watch_anime_database.dart';
import '../models/recent_anime.dart';

/// [RecentWatchManager] keeps track of a list of recently watched anime backing
/// it up in a local database in between app sessions.
class RecentWatchManager extends GetxController {
  RecentWatchManager({RecentAnimeStore? database})
      : _database = database ?? RecentWatchAnimeDatabase.instance;

  final RecentAnimeStore _database;

  /// List of recently watched anime
  List<RecentAnime> _recentAnimes = [];

  List<RecentAnime> get animeList => [..._recentAnimes.reversed];

  /// Loads all locally stored entries from the recent anime local database
  Future<void> loadRecentAnimeFromDatabase() async {
    final result = await _database.getAllRecentAnime();
    _recentAnimes = result;
    update();
  }

  /// Adds a new recent anime entry to the local database
  Future<void> addAnimeToRecent(RecentAnime anime) async {
    await _database.insert(anime);
    _recentAnimes.removeWhere((rm) => (rm.id == anime.id));
    _recentAnimes.add(anime);
    update();
  }

  /// Removes a recent anime entry from the local database with the provided id
  Future<void> removeAnime(String id) async {
    await _database.remove(id);
    _recentAnimes.removeWhere((rm) => rm.id == id);
    update();
  }

  /// Clears all locally stored entries from the recent anime local database
  Future<void> removeAllAnime() async {
    await _database.removeAll();
    _recentAnimes.clear();
    update();
  }
}
