import 'anime.dart';
import 'recent_anime.dart';

/// Catalog identity travels with playback, independently of signed stream URLs.
class PlaybackContext {
  PlaybackContext({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.animeUrl,
    required List<Episode> episodes,
    required this.index,
  }) : episodes = List.unmodifiable(episodes) {
    RangeError.checkValidIndex(index, episodes);
  }

  final String id;
  final String name;
  final String imageUrl;
  final String animeUrl;
  final List<Episode> episodes;
  final int index;

  Episode get episode => episodes[index];
  late final PlaybackContext? next = index + 1 >= episodes.length
      ? null
      : PlaybackContext(
          id: id,
          name: name,
          imageUrl: imageUrl,
          animeUrl: animeUrl,
          episodes: episodes,
          index: index + 1,
        );

  RecentAnime toRecent() => RecentAnime(
        id: id,
        name: name,
        imageUrl: imageUrl,
        animeUrl: animeUrl,
        currentEp: 'Episode ${episode.number}',
        epUrl: episode.link,
      );
}
