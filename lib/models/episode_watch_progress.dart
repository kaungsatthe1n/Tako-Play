/// Playback position saved for one episode of an anime.
class EpisodeWatchProgress {
  const EpisodeWatchProgress({
    required this.animeId,
    required this.episodeUrl,
    required this.episodeNumber,
    required this.positionMillis,
    required this.durationMillis,
    required this.updatedAtMillis,
  });

  final String animeId;
  final String episodeUrl;
  final String episodeNumber;
  final int positionMillis;
  final int durationMillis;
  final int updatedAtMillis;

  int get percentage {
    if (durationMillis <= 0) return 0;
    return ((positionMillis / durationMillis) * 100).round().clamp(0, 100);
  }

  factory EpisodeWatchProgress.fromJson(Map<String, Object?> json) =>
      EpisodeWatchProgress(
        animeId: json['animeId'] as String,
        episodeUrl: json['episodeUrl'] as String,
        episodeNumber: json['episodeNumber'] as String,
        positionMillis: json['positionMillis'] as int,
        durationMillis: json['durationMillis'] as int,
        updatedAtMillis: json['updatedAtMillis'] as int,
      );

  Map<String, Object?> toJson() => {
        'animeId': animeId,
        'episodeUrl': episodeUrl,
        'episodeNumber': episodeNumber,
        'positionMillis': positionMillis,
        'durationMillis': durationMillis,
        'updatedAtMillis': updatedAtMillis,
      };
}
