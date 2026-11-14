import 'package:get/get.dart';

import '../database/recent_watch_anime_database.dart';
import '../models/episode_watch_progress.dart';
import '../models/recent_anime.dart';

/// [RecentWatchManager] keeps track of a list of recently watched anime backing
/// it up in a local database in between app sessions.
class RecentWatchManager extends GetxController {
  RecentWatchManager({RecentAnimeStore? database})
      : _database = database ?? RecentWatchAnimeDatabase.instance;

  final RecentAnimeStore _database;

  /// List of recently watched anime
  List<RecentAnime> _recentAnimes = [];
  final Map<String, EpisodeWatchProgress> _episodeProgress = {};

  String _progressKey(String animeId, String episodeUrl) =>
      '$animeId\u0000$episodeUrl';

  List<RecentAnime> get animeList => [..._recentAnimes.reversed];

  /// The last episode opened for this title, which is also the selection
  /// highlighted in its episode grid.
  RecentAnime? currentEpisodeFor(String id) {
    for (final recent in _recentAnimes.reversed) {
      if (recent.id == id) return recent;
    }
    return null;
  }

  EpisodeWatchProgress? progressFor(String animeId, String episodeUrl) =>
      _episodeProgress[_progressKey(animeId, episodeUrl)];

  Future<void> loadEpisodeProgressForAnime(String animeId) async {
    final database = _database;
    if (database is! EpisodeProgressStore) return;
    final progressStore = database as EpisodeProgressStore;
    try {
      final rows = await progressStore.getEpisodeProgressForAnime(animeId);
      for (final progress in rows) {
        final key = _progressKey(animeId, progress.episodeUrl);
        final cached = _episodeProgress[key];
        if (cached == null ||
            progress.updatedAtMillis > cached.updatedAtMillis) {
          _episodeProgress[key] = progress;
        }
      }
      update();
    } catch (_) {
      // Episode details remain usable if local progress is unavailable.
    }
  }

  Future<void> saveProgress({
    required String animeId,
    required String episodeUrl,
    required String episodeNumber,
    required int positionMillis,
    required int durationMillis,
  }) async {
    if (durationMillis <= 0) return;
    final progress = EpisodeWatchProgress(
      animeId: animeId,
      episodeUrl: episodeUrl,
      episodeNumber: episodeNumber,
      positionMillis: positionMillis.clamp(0, durationMillis),
      durationMillis: durationMillis,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    _episodeProgress[_progressKey(animeId, episodeUrl)] = progress;
    update();
    final database = _database;
    if (database is EpisodeProgressStore) {
      final progressStore = database as EpisodeProgressStore;
      await progressStore.saveEpisodeProgress(progress);
    }
  }

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
