import 'dart:convert';

import 'package:http/http.dart' as http;

import 'playback_service.dart';

/// Warms a few standalone subtitle files, never downloads the next video.
class SubtitlePrefetchService {
  SubtitlePrefetchService({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;

  Future<PlaybackSource> prepare(PlaybackSource source) async {
    final tracks = await Future.wait(source.subtitles.asMap().entries.map(
          (entry) => entry.key < 3
              ? _prepareTrack(entry.value)
              : Future.value(entry.value),
        ));
    return PlaybackSource(
        url: source.url,
        headers: source.headers,
        subtitles: tracks,
        endingStart: source.endingStart,
        opening: source.opening);
  }

  Future<PlaybackSubtitle> _prepareTrack(PlaybackSubtitle track) async {
    try {
      final content = await (() async {
        final response = await _client.send(
            http.Request('GET', Uri.parse(track.url))
              ..headers.addAll(track.headers));
        if (response.statusCode != 200) {
          final subscription = response.stream.listen((_) {});
          await subscription.cancel();
          return null;
        }
        final bytes = <int>[];
        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 5))) {
          if (bytes.length + chunk.length > 2 * 1024 * 1024) return null;
          bytes.addAll(chunk);
        }
        return utf8.decode(bytes);
      })()
          .timeout(const Duration(seconds: 6));
      if (content == null || content.isEmpty) return track;
      return PlaybackSubtitle(
          url: track.url,
          name: track.name,
          headers: track.headers,
          selectedByDefault: track.selectedByDefault,
          content: content);
    } catch (_) {
      return track; // BetterPlayer can fetch this track normally on selection.
    }
  }

  void close() => _client.close();
}
