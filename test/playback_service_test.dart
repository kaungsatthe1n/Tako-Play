import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/services/playback_service.dart';
import 'package:tako_play/utils/constants.dart';

Future<String> _encryptedEmbed(String embedUrl, String pageKey) async {
  final nonce = List<int>.generate(12, (index) => index);
  final secretBox = await AesGcm.with256bits().encrypt(
    utf8.encode(embedUrl),
    secretKey: SecretKey(base64Url.decode(base64Url.normalize(pageKey))),
    nonce: nonce,
  );
  return base64Url.encode(<int>[
    ...nonce,
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ]).replaceAll('=', '');
}

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
              'subtitles': [
                {
                  'url': 'https://cdn.example.com/video/en.vtt',
                  'name': 'English',
                  'default': true,
                },
              ],
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
      expect(source.subtitles, hasLength(1));
      expect(
          source.subtitles.single.url, 'https://cdn.example.com/video/en.vtt');
      expect(source.subtitles.single.name, 'English');
      expect(source.subtitles.single.selectedByDefault, isTrue);
      expect(
          source.subtitles.single.headers, {'Authorization': 'Bearer token'});
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

    test('validates resolver configuration and accepts missing headers',
        () async {
      final missing = PlaybackService(
          client: MockClient((_) async => http.Response('', 200)));
      expect(missing.isConfigured, isFalse);
      await expectLater(
        missing.resolveEpisode('https://catalog/episode'),
        throwsA(isA<PlaybackResolutionException>()),
      );

      final invalid = PlaybackService(
        resolverUrl: '://invalid',
        client: MockClient((_) async => http.Response('', 200)),
      );
      await expectLater(
        invalid.resolveEpisode('https://catalog/episode'),
        throwsA(isA<PlaybackResolutionException>()),
      );

      final noHeaders = PlaybackService(
        resolverUrl: 'https://api.example.com/playback',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'url': 'https://cdn.example.com/master.m3u8'}),
            200,
          ),
        ),
      );
      expect(
          (await noHeaders.resolveEpisode('https://catalog/episode')).headers,
          isEmpty);
    });

    test('extracts an escaped HLS source from an embedded player page',
        () async {
      late http.BaseRequest request;
      final service = PlaybackService(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            '''
              <script>const source = "https:\\/\\/cdn.example.com\\/video\\/master.m3u8?token=abc";</script>
              <track kind="subtitles" src="/captions/en.vtt" label="English" default>
            ''',
            200,
            request: value,
          );
        }),
      );

      final source = await service.resolveEmbeddedPlayers(
        ['https://player.example.com/embed/episode-1'],
        episodeUrl: 'https://catalog.example.com/watch/episode-1',
      );

      expect(request.headers['referer'],
          'https://catalog.example.com/watch/episode-1');
      expect(request.headers['user-agent'], isNotEmpty);
      expect(source.url, 'https://cdn.example.com/video/master.m3u8?token=abc');
      expect(source.headers['Referer'],
          'https://player.example.com/embed/episode-1');
      expect(source.subtitles, hasLength(1));
      expect(source.subtitles.single.url,
          'https://player.example.com/captions/en.vtt');
      expect(source.subtitles.single.name, 'English');
      expect(source.subtitles.single.selectedByDefault, isTrue);
    });

    test('uses the next advertised player when the first has no HLS source',
        () async {
      final service = PlaybackService(
        client: MockClient((request) async {
          if (request.url.host == 'first.example.com') {
            return http.Response('<html>No stream</html>', 200,
                request: request);
          }
          return http.Response(
            '<video><source src="/streams/master.m3u8"></video>',
            200,
            request: request,
          );
        }),
      );

      final source = await service.resolveEmbeddedPlayers(
        [
          'https://first.example.com/embed/episode-1',
          'https://second.example.com/embed/episode-1',
        ],
        episodeUrl: 'https://catalog.example.com/watch/episode-1',
      );

      expect(source.url, 'https://second.example.com/streams/master.m3u8');
    });

    test('resolves the encrypted fragment handoff for native HLS playback',
        () async {
      final pageKey = base64Url
          .encode(List<int>.generate(32, (index) => index))
          .replaceAll('=', '');
      final token = List<String>.filled(40, 'a').join();
      final fragment = '$token.6.2.sub';
      const embedUrl = 'https://media-player.example.com/stream/123/sub';
      final encryptedEmbed = await _encryptedEmbed(embedUrl, pageKey);
      final requests = <http.BaseRequest>[];
      final service = PlaybackService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.host == 'play.gogoanimes.org' &&
              request.url.path == '/watch') {
            return http.Response(
              '<script>const PAGE_KEY="$pageKey";</script>',
              200,
              request: request,
            );
          }
          if (request.url.host == 'play.gogoanimes.org' &&
              request.url.path == '/get/$fragment') {
            return http.Response(
              jsonEncode({'info': encryptedEmbed, 'mode': 'embed'}),
              200,
              request: request,
            );
          }
          if (request.url.toString() == embedUrl) {
            return http.Response(
              '<script>const file="/hls/master.m3u8?token=xyz";</script>',
              200,
              request: request,
            );
          }
          return http.Response('Not found', 404, request: request);
        }),
      );

      final source = await service.resolveEmbeddedPlayers(
        ['https://play.gogoanimes.org/watch#$fragment'],
        episodeUrl: 'https://gogoanimes.org/watch/example-1/#episode=6',
      );

      expect(requests, hasLength(3));
      expect(requests[0].url.fragment, isEmpty);
      expect(requests[0].headers['referer'],
          'https://gogoanimes.org/watch/example-1/');
      expect(
          requests[1].headers['referer'], 'https://play.gogoanimes.org/watch');
      expect(
          requests[2].headers['referer'], 'https://play.gogoanimes.org/watch');
      expect(source.url,
          'https://media-player.example.com/hls/master.m3u8?token=xyz');
      expect(source.headers, {
        'Referer': embedUrl,
        'User-Agent': userAgent,
      });
    });

    test('rejects a tampered encrypted player handoff', () async {
      final pageKey = base64Url
          .encode(List<int>.generate(32, (index) => index + 1))
          .replaceAll('=', '');
      final token = List<String>.filled(40, 'b').join();
      final encrypted = base64Url.decode(base64Url.normalize(
        await _encryptedEmbed('https://player.example.com/embed/1', pageKey),
      ));
      encrypted[20] ^= 1;
      final service = PlaybackService(
        client: MockClient((request) async {
          if (request.url.path == '/watch') {
            return http.Response(
              '<script>const PAGE_KEY="$pageKey";</script>',
              200,
              request: request,
            );
          }
          return http.Response(
            jsonEncode({
              'info': base64Url.encode(encrypted).replaceAll('=', ''),
              'mode': 'embed',
            }),
            200,
            request: request,
          );
        }),
      );

      expect(
        service.resolveEmbeddedPlayers(
          ['https://play.gogoanimes.org/watch#$token.1.2.sub'],
          episodeUrl: 'https://gogoanimes.org/watch/example-1/',
        ),
        throwsA(isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('could not be decoded'),
        )),
      );
    });

    test('validates embedded-player inputs and HTTP failures', () async {
      final service = PlaybackService(
        client: MockClient(
          (request) async => http.Response('gone', 410, request: request),
        ),
      );
      await expectLater(
        service.resolveEmbeddedPlayers(
          const ['https://player.example/embed'],
          episodeUrl: 'http://catalog.example/episode',
        ),
        throwsA(isA<PlaybackResolutionException>()),
      );
      await expectLater(
        service.resolveEmbeddedPlayers(
          const ['not a URL'],
          episodeUrl: 'https://catalog.example/episode',
        ),
        throwsA(isA<PlaybackResolutionException>()),
      );
      await expectLater(
        service.resolveEmbeddedPlayers(
          const ['https://player.example/embed'],
          episodeUrl: 'https://catalog.example/episode',
        ),
        throwsA(isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('returned 410'),
        )),
      );
    });

    test('normalizes unnamed and script-provided subtitle tracks', () async {
      final service = PlaybackService(
        client: MockClient(
          (request) async => http.Response(
            r'''
              <script>const stream = "https://cdn.example.com/master.m3u8"; const captions = ["https:\/\/cdn.example.com\/first.vtt", "\/captions\/second.srt"];</script>
              <track kind="captions" src="/captions/second.srt">
              <track kind="metadata" src="/ignored.vtt">
            ''',
            200,
            request: request,
          ),
        ),
      );
      final source = await service.resolveEmbeddedPlayers(
        const ['https://player.example/embed'],
        episodeUrl: 'https://catalog.example/episode',
      );
      expect(source.subtitles.map((subtitle) => subtitle.name), [
        'Subtitle 1',
        'Subtitle 2',
        'Subtitle 3',
      ]);
      expect(
        source.subtitles.map((subtitle) => subtitle.url),
        containsAll([
          'https://cdn.example.com/first.vtt',
          'https://player.example/captions/second.srt',
        ]),
      );
    });

    test('keeps per-subtitle headers and supports TTML resolver tracks',
        () async {
      final service = PlaybackService(
        resolverUrl: 'https://api.example.com/playback',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'url': 'https://cdn.example.com/master.m3u8',
              'headers': {'Authorization': 'Bearer stream'},
              'tracks': [
                {
                  'file': 'https://cdn.example.com/subtitles/ja.ttml',
                  'language': 'Japanese',
                  'headers': {'X-Subtitle': 'yes'},
                  'selectedByDefault': true,
                },
              ],
            }),
            200,
          ),
        ),
      );

      final source = await service.resolveEpisode('https://catalog.example/1');
      expect(source.subtitles.single.name, 'Japanese');
      expect(source.subtitles.single.headers, {
        'Authorization': 'Bearer stream',
        'X-Subtitle': 'yes',
      });
      expect(source.subtitles.single.selectedByDefault, isTrue);
    });

    test('decodes unicode-escaped player URLs', () async {
      final service = PlaybackService(
        client: MockClient(
          (request) async => http.Response(
            r'<script>const file = "https:\u002f\u002fcdn.example.com\u002fmaster.m3u8";</script>',
            200,
            request: request,
          ),
        ),
      );

      final source = await service.resolveEmbeddedPlayers(
        const ['https://player.example/embed'],
        episodeUrl: 'https://catalog.example/episode',
      );
      expect(source.url, 'https://cdn.example.com/master.m3u8');
    });

    test('reports Gogo handoff status, JSON, and payload failures', () async {
      final pageKey = base64Url
          .encode(List<int>.generate(32, (index) => index))
          .replaceAll('=', '');
      final token = List<String>.filled(40, 'c').join();
      final fragment = '$token.1.2.sub';

      Future<void> expectFailure(http.Response Function(http.BaseRequest) reply,
          String message) async {
        final service = PlaybackService(
          client: MockClient((request) async {
            if (request.url.path == '/watch') {
              return http.Response(
                '<script>const PAGE_KEY="$pageKey";</script>',
                200,
                request: request,
              );
            }
            return reply(request);
          }),
        );
        await expectLater(
          service.resolveEmbeddedPlayers(
            ['https://play.gogoanimes.org/watch#$fragment'],
            episodeUrl: 'https://catalog.example/episode',
          ),
          throwsA(isA<PlaybackResolutionException>().having(
            (error) => error.message,
            'message',
            contains(message),
          )),
        );
      }

      await expectFailure(
        (request) => http.Response('unavailable', 502, request: request),
        'returned 502',
      );
      await expectFailure(
        (request) => http.Response('not-json', 200, request: request),
        'invalid JSON',
      );
      await expectFailure(
        (request) => http.Response(
          jsonEncode({'mode': 'embed', 'info': '%%%'}),
          200,
          request: request,
        ),
        'payload is invalid',
      );
    });

    test('closes its internally-owned client and formats errors', () async {
      final service = PlaybackService(resolverUrl: 'not a URL');
      await expectLater(
        service.resolveEpisode('https://catalog.example/episode'),
        throwsA(isA<PlaybackResolutionException>()),
      );
      expect(
          const PlaybackResolutionException('problem').toString(), 'problem');
    });
  });
}
