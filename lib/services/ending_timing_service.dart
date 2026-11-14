import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/playback_context.dart';

/// Best-effort ending metadata. Failure must never block video playback.
/// AniList supplies a MAL identity; AniSkip supplies episode-specific ED times.
class EndingTimingService {
  EndingTimingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Future<Map?>> _identities = {};
  static const _timeout = Duration(seconds: 6);

  Future<Duration?> fetchEnding(
    PlaybackContext context,
    Duration duration,
  ) async =>
      (await _fetchInterval(context, duration, type: 'ed'))?.start;

  Future<SkipInterval?> _fetchInterval(
    PlaybackContext context,
    Duration duration, {
    required String type,
  }) async {
    final episode = int.tryParse(context.episode.number);
    if (episode == null || episode < 1 || duration <= Duration.zero) {
      return null;
    }
    try {
      final identity = await _identityFor(context.name);
      if (identity == null) return null;
      final count = identity['episodes'];
      // Do not guess season offsets for catalogs using absolute numbering.
      if (count is int && episode > count) return null;
      final seconds = duration.inMilliseconds / 1000;
      final uri = Uri.https(
          'api.aniskip.com', '/v2/skip-times/${identity['idMal']}/$episode', {
        'types[]': type,
        'episodeLength': seconds.toStringAsFixed(3),
      });
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['found'] != true || data['results'] is! List) {
        return null;
      }
      for (final result in data['results'] as List) {
        if (result is! Map || result['skipType'] != type) continue;
        final interval = result['interval'];
        final length = result['episodeLength'];
        if (interval is! Map ||
            length is! num ||
            !length.isFinite ||
            (length - seconds).abs() > 5) {
          continue;
        }
        final start = interval['startTime'];
        final end = interval['endTime'];
        if (start is num &&
            end is num &&
            start.isFinite &&
            end.isFinite &&
            (type == 'op' ? start < seconds / 2 : start >= seconds / 2) &&
            end > start &&
            end <= seconds) {
          return SkipInterval(
            start: Duration(milliseconds: (start * 1000).round()),
            end: Duration(milliseconds: (end * 1000).round()),
          );
        }
      }
    } catch (_) {
      // Offline, no match, malformed data and rate limits all use the fallback.
    }
    return null;
  }

  Future<Map?> _identityFor(String title) async {
    final pending = _identities.putIfAbsent(title, () => _findIdentity(title));
    try {
      final identity = await pending;
      if (identity == null && identical(_identities[title], pending)) {
        // The future is the cached value being removed, not pending work.
        // ignore: unawaited_futures
        _identities.remove(title);
      }
      return identity;
    } catch (_) {
      if (identical(_identities[title], pending)) {
        // ignore: unawaited_futures
        _identities.remove(title);
      }
      rethrow;
    }
  }

  Future<Map?> _findIdentity(String title) async {
    final queryTitle = title
        .replaceFirst(
          RegExp(r'\s*\((?:dub|sub)\)\s*$', caseSensitive: false),
          '',
        )
        .trim();
    if (queryTitle.isEmpty) return null;
    final response = await _client
        .post(
          Uri.https('graphql.anilist.co', ''),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode({
            'query': r'''query ($search: String!) {
          Page(perPage: 50) {
            pageInfo { hasNextPage }
            media(search: $search, type: ANIME) {
              idMal episodes title { romaji english native } synonyms
            }
          }
        }''',
            'variables': {'search': queryTitle},
          }),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    final page = decoded['data']?['Page'];
    if (page is! Map ||
        page['media'] is! List ||
        page['pageInfo']?['hasNextPage'] == true) {
      return null;
    }
    final matches = (page['media'] as List).whereType<Map>().where((item) {
      final names = item['title'];
      if (names is! Map || item['idMal'] is! int || item['idMal'] <= 0) {
        return false;
      }
      final aliases = <dynamic>[
        ...names.values,
        if (item['synonyms'] is List) ...item['synonyms'] as List
      ];
      return aliases
          .whereType<String>()
          .any((name) => _normalize(name) == _normalize(queryTitle));
    }).toList();
    // Search ranking is not identity: ambiguous or fuzzy matches are rejected.
    return matches.length == 1 ? matches.single : null;
  }

  String _normalize(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  void close() => _client.close();
}

class SkipInterval {
  const SkipInterval({required this.start, required this.end});
  final Duration start;
  final Duration end;
}
