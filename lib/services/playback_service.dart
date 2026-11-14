import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import '../utils/subtitle_name.dart';
import 'ending_timing_service.dart';

/// Resolves an episode to a short-lived HLS URL issued by the app owner's API.
///
/// Configure the endpoint at build time instead of shipping a third-party
/// player's decryption logic in the client:
///
/// ```
/// flutter run --dart-define=PLAYBACK_RESOLVER_URL=https://api.example.com/v1/playback
/// ```
///
/// The endpoint receives `episodeUrl` and should return:
/// ```json
/// {
///   "url": "https://cdn.example.com/.../master.m3u8",
///   "headers": {},
///   "endingStartSeconds": 1284.5,
///   "opening": {"start": 86.4, "end": 111.2},
///   "subtitles": [
///     {"url": "https://cdn.example.com/.../en.vtt", "name": "English"}
///   ]
/// }
/// ```
class PlaybackService {
  PlaybackService({http.Client? client, String? resolverUrl})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _resolverUrl = resolverUrl ?? _configuredResolverUrl;

  static const _configuredResolverUrl =
      String.fromEnvironment('PLAYBACK_RESOLVER_URL');
  static const _playerCandidateHedgeDelay = Duration(milliseconds: 350);
  final http.Client _client;
  final bool _ownsClient;
  final String _resolverUrl;

  bool get isConfigured => _resolverUrl.isNotEmpty;

  Future<PlaybackSource> resolveEpisode(String episodeUrl) async {
    if (!isConfigured) {
      throw const PlaybackResolutionException(
          'Playback API is not configured.');
    }

    try {
      final resolverUri = Uri.tryParse(_resolverUrl);
      if (resolverUri == null) {
        throw const PlaybackResolutionException(
          'Playback API URL is invalid.',
        );
      }
      final resolver = resolverUri.replace(
        queryParameters: {
          ...resolverUri.queryParameters,
          'episodeUrl': episodeUrl,
        },
      );
      if (resolver.scheme != 'https') {
        throw const PlaybackResolutionException(
          'Playback API must use HTTPS.',
        );
      }
      final response = await _client.get(
        resolver,
        headers: const {
          'Accept': 'application/json',
          'X-Client-Platform': 'flutter',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw PlaybackResolutionException(
          'Playback API returned ${response.statusCode}.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const PlaybackResolutionException(
          'Playback API returned invalid JSON.',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const PlaybackResolutionException(
            'Playback API returned invalid JSON.');
      }

      final streamUrl = decoded['url'];
      if (streamUrl is! String || !_isHlsUrl(streamUrl)) {
        throw const PlaybackResolutionException(
            'Playback API did not return an HTTPS HLS URL.');
      }

      final responseHeaders = decoded['headers'];
      final headers = responseHeaders is Map
          ? responseHeaders.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : <String, String>{};
      return PlaybackSource(
        url: streamUrl,
        headers: headers,
        subtitles: preferEnglishSubtitle(
          _subtitlesFromResolverResponse(decoded, headers),
        ),
        endingStart: parseEndingIntervalStart(decoded['ending']) ??
            parseEndingStart(decoded['endingStartSeconds']),
        opening: parseOpeningInterval(decoded['opening']) ??
            parseOpeningTimes(
              decoded['openingStartSeconds'],
              decoded['openingEndSeconds'],
            ),
      );
    } on TimeoutException {
      throw const PlaybackResolutionException('Playback API timed out.');
    } finally {
      if (_ownsClient) _client.close();
    }
  }

  /// Resolves an HLS source advertised by an external player page.
  ///
  /// Besides ordinary `<source>` tags and JSON player configuration, this
  /// supports the catalog's current fragment-based player handoff. That page
  /// supplies its own key and public API response for locating the real embed;
  /// no media DRM is handled here. The final player referrer is forwarded to
  /// Better Player because CDNs can validate it for manifests and segments.
  Future<PlaybackSource> resolveEmbeddedPlayers(
    Iterable<String> playerUrls, {
    required String episodeUrl,
  }) async {
    final episodeUri = Uri.tryParse(episodeUrl);
    if (episodeUri == null ||
        episodeUri.scheme != 'https' ||
        episodeUri.host.isEmpty) {
      throw const PlaybackResolutionException('Episode URL is invalid.');
    }

    try {
      final candidates = playerUrls.toList(growable: false);
      if (candidates.isEmpty) {
        throw const PlaybackResolutionException(
          'No playable HLS source was found in the embedded players.',
        );
      }
      return await _resolveFirstPlayableCandidate(candidates, episodeUri);
    } finally {
      if (_ownsClient) _client.close();
    }
  }

  /// Starts the provider's first candidate immediately, then hedges against
  /// slow or unavailable servers. This preserves the provider's priority when
  /// it is healthy without making every fallback wait for a full request
  /// timeout.
  Future<PlaybackSource> _resolveFirstPlayableCandidate(
    List<String> candidates,
    Uri episodeUri,
  ) {
    final result = Completer<PlaybackSource>();
    var failedCandidates = 0;
    PlaybackResolutionException? lastError;

    for (var index = 0; index < candidates.length; index++) {
      final playerUrl = candidates[index];
      unawaited(() async {
        if (index > 0) {
          await Future<void>.delayed(
            Duration(
              milliseconds: _playerCandidateHedgeDelay.inMilliseconds * index,
            ),
          );
        }
        if (result.isCompleted) return;

        try {
          final source = await _resolveEmbeddedPlayer(playerUrl, episodeUri);
          if (!result.isCompleted) result.complete(source);
        } on PlaybackResolutionException catch (error) {
          lastError = error;
          _completeAfterCandidateFailure(
              result, ++failedCandidates, candidates.length, lastError);
        } catch (_) {
          lastError = const PlaybackResolutionException(
            'An embedded player could not be resolved.',
          );
          _completeAfterCandidateFailure(
              result, ++failedCandidates, candidates.length, lastError);
        }
      }());
    }

    return result.future;
  }

  void _completeAfterCandidateFailure(
    Completer<PlaybackSource> result,
    int failedCandidates,
    int candidateCount,
    PlaybackResolutionException? lastError,
  ) {
    if (failedCandidates != candidateCount || result.isCompleted) return;
    result.completeError(
      lastError ??
          const PlaybackResolutionException(
            'No playable HLS source was found in the embedded players.',
          ),
    );
  }

  Future<PlaybackSource> _resolveEmbeddedPlayer(
    String playerUrl,
    Uri referrerUri, {
    bool resolveGogoHandoff = true,
  }) async {
    final playerUri = Uri.tryParse(playerUrl);
    if (playerUri == null ||
        playerUri.scheme != 'https' ||
        playerUri.host.isEmpty) {
      throw const PlaybackResolutionException(
          'Embedded player URL is invalid.');
    }

    try {
      // URL fragments are browser-only state. Keep the original fragment for
      // the player API, but never include it in the HTTP request or referrer.
      final requestUri = playerUri.removeFragment();
      final response = await _client.get(
        requestUri,
        headers: {
          'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
          'Referer': referrerUri.removeFragment().toString(),
          'User-Agent': userAgent,
          'X-Client-Platform': 'flutter',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PlaybackResolutionException(
          'Embedded player returned ${response.statusCode}.',
        );
      }

      // `http` follows redirects, so use the final request URL when resolving
      // relative manifest links and constructing the media referrer.
      final resolvedPlayerUri = response.request?.url ?? requestUri;
      if (resolveGogoHandoff &&
          _isGogoPlayer(resolvedPlayerUri) &&
          playerUri.fragment.isNotEmpty) {
        final embedUri = await _resolveGogoHandoff(
          response,
          resolvedPlayerUri,
          playerUri.fragment,
        );
        return await _resolveEmbeddedPlayer(
          embedUri.toString(),
          resolvedPlayerUri,
          resolveGogoHandoff: false,
        );
      }

      final streamUri = _streamUriFromResponse(response, resolvedPlayerUri);
      if (streamUri == null || !_isHlsUrl(streamUri.toString())) {
        throw const PlaybackResolutionException(
          'Embedded player did not expose an HTTPS HLS URL.',
        );
      }

      return PlaybackSource(
        url: streamUri.toString(),
        headers: {
          'Referer': resolvedPlayerUri.removeFragment().toString(),
          'User-Agent': userAgent,
        },
        subtitles: preferEnglishSubtitle(
          _subtitlesFromPlayerResponse(
            response,
            resolvedPlayerUri,
            headers: {
              'Referer': resolvedPlayerUri.removeFragment().toString(),
              'User-Agent': userAgent,
            },
          ),
        ),
      );
    } on TimeoutException {
      throw const PlaybackResolutionException('Embedded player timed out.');
    }
  }

  bool _isGogoPlayer(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host.toLowerCase() == 'play.gogoanimes.org' &&
      uri.path == '/watch';

  Future<Uri> _resolveGogoHandoff(
    http.Response playerResponse,
    Uri playerUri,
    String fragment,
  ) async {
    if (!_gogoFragmentPattern.hasMatch(fragment)) {
      throw const PlaybackResolutionException(
        'Embedded player episode data is invalid.',
      );
    }
    final pageKey =
        _gogoPageKeyPattern.firstMatch(playerResponse.body)?.group(1);
    if (pageKey == null) {
      throw const PlaybackResolutionException(
        'Embedded player did not expose its handoff key.',
      );
    }

    // The browser player calls this same public endpoint after reading the
    // fragment. Dots separate token, episode, server, and language.
    final handoffUri = Uri(
      scheme: 'https',
      host: playerUri.host,
      port: playerUri.port,
      path: '/get/$fragment',
    );
    final response = await _client.get(
      handoffUri,
      headers: {
        'Accept': 'application/json',
        'Referer': playerUri.removeFragment().toString(),
        'User-Agent': userAgent,
        'X-Client-Platform': 'flutter',
      },
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw PlaybackResolutionException(
        'Embedded player handoff returned ${response.statusCode}.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const PlaybackResolutionException(
        'Embedded player handoff returned invalid JSON.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const PlaybackResolutionException(
        'Embedded player handoff returned invalid JSON.',
      );
    }
    if (decoded['mode'] != 'embed' || decoded['info'] is! String) {
      throw const PlaybackResolutionException(
        'Embedded player did not return a playable embed.',
      );
    }

    final encrypted = _decodeBase64Url(decoded['info'] as String);
    final key = _decodeBase64Url(pageKey);
    // Browser AES-GCM data is nonce || ciphertext || 16-byte auth tag.
    if (encrypted.length < 29) {
      throw const PlaybackResolutionException(
        'Embedded player handoff payload is invalid.',
      );
    }

    late final String embedUrl;
    try {
      final plaintext = await AesGcm.with256bits().decrypt(
        SecretBox(
          encrypted.sublist(12, encrypted.length - 16),
          nonce: encrypted.sublist(0, 12),
          mac: Mac(encrypted.sublist(encrypted.length - 16)),
        ),
        secretKey: SecretKey(key),
      );
      embedUrl = utf8.decode(plaintext);
    } on Exception {
      throw const PlaybackResolutionException(
        'Embedded player handoff could not be decoded.',
      );
    }

    final embedUri = Uri.tryParse(embedUrl);
    if (embedUri == null ||
        embedUri.scheme != 'https' ||
        embedUri.host.isEmpty) {
      throw const PlaybackResolutionException(
        'Embedded player returned an invalid embed URL.',
      );
    }
    return embedUri;
  }

  List<int> _decodeBase64Url(String value) {
    try {
      return base64Url.decode(base64Url.normalize(value));
    } on FormatException {
      throw const PlaybackResolutionException(
        'Embedded player handoff payload is invalid.',
      );
    }
  }

  Uri? _streamUriFromResponse(http.Response response, Uri playerUri) {
    if (_isHlsUrl(playerUri.toString())) return playerUri;

    final normalizedBody = _decodeEscapedUrls(response.body);
    for (final match in _hlsUrlPattern.allMatches(normalizedBody)) {
      final candidate = match.group(0);
      final streamUri = candidate == null ? null : playerUri.resolve(candidate);
      if (streamUri != null && _isHlsUrl(streamUri.toString())) {
        return streamUri;
      }
    }

    for (final match in _quotedHlsPathPattern.allMatches(normalizedBody)) {
      final candidate = match.group(1);
      final streamUri = candidate == null ? null : playerUri.resolve(candidate);
      if (streamUri != null && _isHlsUrl(streamUri.toString())) {
        return streamUri;
      }
    }
    return null;
  }

  List<PlaybackSubtitle> _subtitlesFromResolverResponse(
    Map<String, dynamic> response,
    Map<String, String> streamHeaders,
  ) {
    final rawSubtitles = response['subtitles'] ?? response['tracks'];
    final values = rawSubtitles is List ? rawSubtitles : [rawSubtitles];
    return _subtitleSourcesFromValues(
      values,
      baseUri: null,
      defaultHeaders: streamHeaders,
    );
  }

  List<PlaybackSubtitle> _subtitlesFromPlayerResponse(
    http.Response response,
    Uri playerUri, {
    required Map<String, String> headers,
  }) {
    final subtitles = <PlaybackSubtitle>[];
    final document = html_parser.parse(response.body);

    // Standard HTML tracks are the most reliable source because their
    // language, label, and default state are explicitly declared.
    for (final track in document.querySelectorAll('track')) {
      final kind = track.attributes['kind']?.toLowerCase();
      if (kind != 'subtitles' && kind != 'captions') continue;
      final subtitle = _subtitleFromValue(
        {
          'url': track.attributes['src'],
          'name': track.attributes['label'] ?? track.attributes['srclang'],
          'default': track.attributes.containsKey('default'),
        },
        baseUri: playerUri,
        defaultHeaders: headers,
      );
      if (subtitle != null) subtitles.add(subtitle);
    }

    // Some hosted players keep the subtitle list in JavaScript rather than in
    // <track> tags. Collect only direct VTT/SRT/TTML URLs; this avoids treating
    // arbitrary script URLs as captions.
    final normalizedBody = _decodeEscapedUrls(response.body);
    for (final match in _subtitleUrlPattern.allMatches(normalizedBody)) {
      final subtitle = _subtitleFromValue(
        match.group(1),
        baseUri: playerUri,
        defaultHeaders: headers,
      );
      if (subtitle != null) subtitles.add(subtitle);
    }

    return _deduplicateSubtitles(subtitles);
  }

  List<PlaybackSubtitle> _subtitleSourcesFromValues(
    Iterable<dynamic> values, {
    required Uri? baseUri,
    required Map<String, String> defaultHeaders,
  }) =>
      _deduplicateSubtitles(
        values
            .map(
              (value) => _subtitleFromValue(
                value,
                baseUri: baseUri,
                defaultHeaders: defaultHeaders,
              ),
            )
            .whereType<PlaybackSubtitle>(),
      );

  PlaybackSubtitle? _subtitleFromValue(
    dynamic value, {
    required Uri? baseUri,
    required Map<String, String> defaultHeaders,
  }) {
    final metadata = value is Map ? value : null;
    final rawUrl = value is String
        ? value
        : metadata?['url'] ?? metadata?['file'] ?? metadata?['src'];
    if (rawUrl is! String) return null;

    final subtitleUri = baseUri?.resolve(rawUrl) ?? Uri.tryParse(rawUrl);
    if (subtitleUri == null ||
        subtitleUri.scheme != 'https' ||
        subtitleUri.host.isEmpty ||
        !_isSubtitleUrl(subtitleUri)) {
      return null;
    }

    final rawHeaders = metadata?['headers'];
    final subtitleHeaders = <String, String>{
      ...defaultHeaders,
      if (rawHeaders is Map)
        ...rawHeaders.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
    };
    final rawName =
        metadata?['name'] ?? metadata?['label'] ?? metadata?['language'];
    return PlaybackSubtitle(
      url: subtitleUri.toString(),
      name: subtitleDisplayName(
        rawName is String ? rawName : null,
        subtitleUri.toString(),
      ),
      headers: subtitleHeaders,
      selectedByDefault: metadata?['default'] == true ||
          metadata?['selectedByDefault'] == true,
    );
  }

  List<PlaybackSubtitle> _deduplicateSubtitles(
    Iterable<PlaybackSubtitle> subtitles,
  ) {
    final urls = <String>{};
    var unnamedTrackNumber = 0;
    return subtitles
        .where((subtitle) => urls.add(subtitle.url))
        .map((subtitle) {
      if (!RegExp(r'^Subtitle\s*\d+$', caseSensitive: false)
          .hasMatch(subtitle.name)) {
        return subtitle;
      }
      unnamedTrackNumber += 1;
      return PlaybackSubtitle(
        url: subtitle.url,
        name: subtitleDisplayName(
          subtitle.name,
          subtitle.url,
          fallbackIndex: unnamedTrackNumber,
        ),
        headers: subtitle.headers,
        selectedByDefault: subtitle.selectedByDefault,
      );
    }).toList();
  }

  String _decodeEscapedUrls(String value) => value
          .replaceAll(r'\/', '/')
          .replaceAll('&amp;', '&')
          .replaceAllMapped(_unicodeEscapePattern, (match) {
        return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
      });

  static final _gogoFragmentPattern = RegExp(
    r'^[A-Za-z0-9_-]{32,}\.\d+(?:\.\d+)?\.\d+\.(?:sub|dub)$',
  );
  static final _gogoPageKeyPattern = RegExp(
    r'''PAGE_KEY\s*=\s*["']([A-Za-z0-9_-]{32,})["']''',
  );
  static final _hlsUrlPattern = RegExp(
    r'''(?:https?:)?//[^\s"'<>]+?\.m3u8(?:\?[^\s"'<>]*)?''',
    caseSensitive: false,
  );
  static final _quotedHlsPathPattern = RegExp(
    r'''["']([^"']+\.m3u8(?:\?[^"']*)?)["']''',
    caseSensitive: false,
  );
  static final _unicodeEscapePattern = RegExp(r'\\u([0-9a-fA-F]{4})');
  static final _subtitleUrlPattern = RegExp(
    r'''["']([^"']+\.(?:vtt|srt|ttml)(?:\?[^"']*)?)["']''',
    caseSensitive: false,
  );

  bool _isHlsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        uri.path.toLowerCase().endsWith('.m3u8');
  }

  bool _isSubtitleUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.vtt') ||
        path.endsWith('.srt') ||
        path.endsWith('.ttml');
  }
}

class PlaybackSource {
  const PlaybackSource({
    required this.url,
    required this.headers,
    this.subtitles = const [],
    this.endingStart,
    this.opening,
  });

  final String url;
  final Map<String, String> headers;
  final List<PlaybackSubtitle> subtitles;
  final Duration? endingStart;
  final SkipInterval? opening;
}

SkipInterval? parseOpeningInterval(dynamic value) {
  if (value is List && value.length >= 2) {
    return parseOpeningTimes(value[0], value[1]);
  }
  if (value is! Map) return null;
  return parseOpeningTimes(
    value['start'] ?? value['startTime'] ?? value[0],
    value['end'] ?? value['endTime'] ?? value[1],
  );
}

SkipInterval? parseOpeningTimes(dynamic start, dynamic end) {
  if (start is! num || end is! num || !start.isFinite || !end.isFinite) {
    return null;
  }
  if (start < 0 || end <= start || end > 600) return null;
  return SkipInterval(
    start: Duration(milliseconds: (start * 1000).round()),
    end: Duration(milliseconds: (end * 1000).round()),
  );
}

Duration? parseEndingIntervalStart(dynamic value) {
  if (value is List && value.length >= 2) {
    return _parseEndingInterval(value[0], value[1]);
  }
  if (value is! Map) return null;
  final start = value['start'] ?? value['startTime'] ?? value[0];
  final end = value['end'] ?? value['endTime'] ?? value[1];
  return _parseEndingInterval(start, end);
}

Duration? _parseEndingInterval(dynamic start, dynamic end) {
  if (start is! num || end is! num || !start.isFinite || !end.isFinite) {
    return null;
  }
  if (start < 0 || end <= start || end >= 86400) return null;
  return Duration(milliseconds: (start * 1000).round());
}

/// Optional resolver metadata uses seconds from the start of this exact video.
Duration? parseEndingStart(dynamic value) =>
    value is num && value.isFinite && value > 0 && value < 86400
        ? Duration(milliseconds: (value * 1000).round())
        : null;

class PlaybackSubtitle {
  const PlaybackSubtitle({
    required this.url,
    required this.name,
    required this.headers,
    this.selectedByDefault = false,
    this.content,
  });

  final String url;
  final String name;
  final Map<String, String> headers;
  final bool selectedByDefault;
  final String? content;
}

/// Marks the first English subtitle as the default when one is available.
/// If the episode has no English track, provider defaults are preserved.
List<PlaybackSubtitle> preferEnglishSubtitle(
  Iterable<PlaybackSubtitle> subtitles,
) {
  final tracks = subtitles.toList(growable: false);
  final englishIndex = tracks.indexWhere(
    (subtitle) => isEnglishSubtitleName(subtitle.name),
  );
  if (englishIndex < 0) return tracks;

  return [
    for (var index = 0; index < tracks.length; index++)
      PlaybackSubtitle(
        url: tracks[index].url,
        name: tracks[index].name,
        headers: tracks[index].headers,
        selectedByDefault: index == englishIndex,
        content: tracks[index].content,
      ),
  ];
}

class PlaybackResolutionException implements Exception {
  const PlaybackResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}
