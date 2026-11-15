import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/models/episode_watch_progress.dart';

void main() {
  test('progress serializes and clamps its percentage', () {
    const progress = EpisodeWatchProgress(
      animeId: 'anime',
      episodeUrl: 'episode',
      episodeNumber: '1',
      positionMillis: 120,
      durationMillis: 100,
      updatedAtMillis: 42,
    );
    final restored = EpisodeWatchProgress.fromJson(progress.toJson());
    expect(restored.toJson(), progress.toJson());
    expect(restored.percentage, 100);
    expect(
        const EpisodeWatchProgress(
          animeId: 'anime',
          episodeUrl: 'episode',
          episodeNumber: '1',
          positionMillis: 0,
          durationMillis: 0,
          updatedAtMillis: 0,
        ).percentage,
        0);
    expect(
        const EpisodeWatchProgress(
          animeId: 'anime',
          episodeUrl: 'episode',
          episodeNumber: '1',
          positionMillis: -1,
          durationMillis: 100,
          updatedAtMillis: 0,
        ).percentage,
        0);
  });
}
