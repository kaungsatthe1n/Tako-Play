import 'package:get/get.dart';

import '../database/recent_watch_anime_database.dart';
import '../models/recent_anime.dart';

/// [RecentWatchManager] keeps track of a list of recently watched anime backing
/// it up in a local database in between app sessions.
class RecentWatchManager extends GetxController {
  /// List of recently watched anime
  List<RecentAnime> _recentAnimes = [];

  List<RecentAnime> get animeList => [..._recentAnimes.reversed];

  /// Loads all locally stored entries from the recent anime local database
  Future<void> loadRecentAnimeFromDatabase() async {
    final result = await RecentWatchAnimeDatabase.instance.getAllRecentAnime();
    if (result != null) {
      _recentAnimes = result;
    }
  }

  /// Adds a new recent anime entry to the local database
  void addAnimeToRecent(RecentAnime anime) {
    for (var rm in _recentAnimes) {
      if (rm.id == anime.id) {
        RecentWatchAnimeDatabase.instance.remove(anime.id);
      }
    }
    _recentAnimes.removeWhere((rm) => (rm.id == anime.id));
    _recentAnimes.add(anime);
    RecentWatchAnimeDatabase.instance.insert(anime);
    update();
  }

  /// Removes a recent anime entry from the local database with the provided id
  void removeAnime(String id) {
    _recentAnimes.removeWhere((rm) => rm.id == id);
    RecentWatchAnimeDatabase.instance.remove(id);
    update();
  }

  /// Clears all locally stored entries from the recent anime local database
  void removeAllAnime() {
    _recentAnimes.clear();
    RecentWatchAnimeDatabase.instance.removeAll();
    update();
  }
}
