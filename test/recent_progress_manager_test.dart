import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/database/recent_watch_anime_database.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/episode_watch_progress.dart';
import 'package:tako_play/models/recent_anime.dart';

class _Store implements RecentAnimeStore, EpisodeProgressStore {
  List<EpisodeWatchProgress> rows = [];
  bool failRead = false;
  @override
  Future<List<EpisodeWatchProgress>> getEpisodeProgressForAnime(
      String id) async {
    if (failRead) throw StateError('unavailable');
    return rows.where((row) => row.animeId == id).toList();
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeWatchProgress progress) async {
    rows.add(progress);
  }

  @override
  Future<List<RecentAnime>> getAllRecentAnime() async => [];
  @override
  Future<void> insert(RecentAnime anime) async {}
  @override
  Future<int> remove(String id) async => 0;
  @override
  Future<int> removeAll() async => 0;
}

void main() {
  test('loads newest progress and keeps cached data when storage fails',
      () async {
    final store = _Store();
    EpisodeWatchProgress entry(int position, int timestamp) =>
        EpisodeWatchProgress(
          animeId: 'show',
          episodeUrl: '/1',
          episodeNumber: '1',
          positionMillis: position,
          durationMillis: 100,
          updatedAtMillis: timestamp,
        );
    store.rows = [entry(10, 1), entry(30, 3), entry(20, 2)];
    final manager = RecentWatchManager(database: store);
    await manager.loadEpisodeProgressForAnime('show');
    expect(manager.progressFor('show', '/1')?.positionMillis, 30);
    store.failRead = true;
    await manager.loadEpisodeProgressForAnime('show');
    expect(manager.progressFor('show', '/1')?.positionMillis, 30);
    await manager.saveProgress(
        animeId: 'show',
        episodeUrl: '/2',
        episodeNumber: '2',
        positionMillis: 150,
        durationMillis: 100);
    expect(store.rows.last.positionMillis, 100);
  });
}
