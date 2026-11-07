import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
/// `{ "url": "https://cdn.example.com/.../master.m3u8", "headers": {} }`.
class PlaybackService {
  PlaybackService({http.Client? client, String? resolverUrl})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _resolverUrl = resolverUrl ?? _configuredResolverUrl;

  static const _configuredResolverUrl =
      String.fromEnvironment('PLAYBACK_RESOLVER_URL');
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
      return PlaybackSource(url: streamUrl, headers: headers);
    } on TimeoutException {
      throw const PlaybackResolutionException('Playback API timed out.');
    } finally {
      if (_ownsClient) _client.close();
    }
  }

  bool _isHlsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        uri.path.toLowerCase().endsWith('.m3u8');
  }
}

class PlaybackSource {
  const PlaybackSource({required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;
}

class PlaybackResolutionException implements Exception {
  const PlaybackResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}
