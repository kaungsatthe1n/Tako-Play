import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/services/playback_service.dart';

void main() {
  group('PlaybackService', () {
    test('resolves a secure HLS stream and preserves resolver headers',
        () async {
      late http.BaseRequest request;
      final service = PlaybackService(
        resolverUrl: 'https://api.example.com/playback?client=tako',
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'url': 'https://cdn.example.com/video/master.m3u8',
              'headers': {'Authorization': 'Bearer token'},
            }),
            200,
          );
        }),
      );

      final source = await service.resolveEpisode('https://catalog/episode-1');

      expect(request.url.queryParameters['client'], 'tako');
      expect(request.url.queryParameters['episodeUrl'],
          'https://catalog/episode-1');
      expect(request.headers['accept'], 'application/json');
      expect(source.url, 'https://cdn.example.com/video/master.m3u8');
      expect(source.headers, {'Authorization': 'Bearer token'});
    });

    test('rejects an insecure stream URL from the resolver', () async {
      final service = PlaybackService(
        resolverUrl: 'https://api.example.com/playback',
        client: MockClient(
          (_) async => http.Response(
              jsonEncode({
                'url': 'http://cdn.example.com/video/master.m3u8',
              }),
              200),
        ),
      );

      expect(
        service.resolveEpisode('https://catalog/episode-1'),
        throwsA(isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('HTTPS HLS URL'),
        )),
      );
    });

    test('rejects a resolver endpoint that is not HTTPS', () async {
      final service = PlaybackService(
        resolverUrl: 'http://api.example.com/playback',
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(
        service.resolveEpisode('https://catalog/episode-1'),
        throwsA(isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('must use HTTPS'),
        )),
      );
    });

    test('turns invalid resolver JSON into a playback error', () async {
      final service = PlaybackService(
        resolverUrl: 'https://api.example.com/playback',
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      expect(
        service.resolveEpisode('https://catalog/episode-1'),
        throwsA(isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('invalid JSON'),
        )),
      );
    });

    test('reports an unavailable resolver response', () async {
      final service = PlaybackService(
        resolverUrl: 'https://api.example.com/playback',
        client: MockClient((_) async => http.Response('unavailable', 503)),
      );

      expect(
        service.resolveEpisode('https://catalog/episode-1'),
        throwsA(isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('returned 503'),
        )),
      );
    });
  });
}
