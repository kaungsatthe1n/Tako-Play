import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/models/playback_context.dart';
import 'package:tako_play/services/ending_timing_service.dart';

PlaybackContext context({String number = '2'}) => PlaybackContext(
    id: 'catalog-id',
    name: 'Example (Dub)',
    imageUrl: '',
    animeUrl: '/example',
    episodes: [Episode(number: number, link: '/episode')],
    index: 0);

Map<String, dynamic> title({int id = 123, String name = 'Example'}) => {
      'idMal': id,
      'title': {'romaji': name},
      'synonyms': [],
      'episodes': 12,
    };

http.Response titles(List<Map> items) => http.Response(
    jsonEncode({
      'data': {
        'Page': {
          'pageInfo': {'hasNextPage': false},
          'media': items
        }
      },
    }),
    200);

http.Response timing(
        {num start = 1300,
        num end = 1390,
        num length = 1440,
        String type = 'ed'}) =>
    http.Response(
        jsonEncode({
          'found': true,
          'results': [
            {
              'skipType': type,
              'episodeLength': length,
              'interval': {'startTime': start, 'endTime': end}
            }
          ],
        }),
        200);

void main() {
  test('fetches duration-matched ED with cached exact MAL identity', () async {
    var lookups = 0;
    final service = EndingTimingService(client: MockClient((request) async {
      if (request.url.host == 'graphql.anilist.co') {
        lookups++;
        expect(jsonDecode(request.body)['variables']['search'], 'Example');
        return titles([title()]);
      }
      expect(request.url.path, '/v2/skip-times/123/2');
      expect(request.url.queryParameters['types[]'], 'ed');
      expect(request.url.queryParameters['episodeLength'], '1440.000');
      return timing(start: 1300.5);
    }));
    addTearDown(service.close);
    for (var i = 0; i < 2; i++) {
      expect(
          await service.fetchEnding(context(), const Duration(seconds: 1440)),
          const Duration(milliseconds: 1300500));
    }
    expect(lookups, 1);
  });

  test('retries an identity lookup after a transient API failure', () async {
    var identityLookups = 0;
    final service = EndingTimingService(client: MockClient((request) async {
      if (request.url.host == 'graphql.anilist.co') {
        if (++identityLookups == 1) return http.Response('offline', 503);
        return titles([title()]);
      }
      return timing(start: 1300.5);
    }));
    addTearDown(service.close);

    expect(
      await service.fetchEnding(context(), const Duration(seconds: 1440)),
      isNull,
    );
    expect(
      await service.fetchEnding(context(), const Duration(seconds: 1440)),
      const Duration(milliseconds: 1300500),
    );
    expect(identityLookups, 2);
  });

  for (final candidates in [
    [title(name: 'Example Season 2')],
    [title(), title(id: 456)],
  ]) {
    test('rejects fuzzy or ambiguous title candidates: $candidates', () async {
      var requests = 0;
      final service = EndingTimingService(client: MockClient((_) async {
        requests++;
        return titles(candidates);
      }));
      addTearDown(service.close);
      expect(
          await service.fetchEnding(context(), const Duration(seconds: 1440)),
          isNull);
      expect(requests, 1);
    });
  }

  for (final response in [
    timing(length: 1500),
    timing(start: 40),
    timing(end: 1500),
    timing(type: 'mixed-ed'),
    timing(start: 1390, end: 1300),
    http.Response('bad JSON', 200),
    http.Response('rate limit', 429),
    http.Response('{"found":false,"results":[]}', 200)
  ]) {
    test('ignores unsafe, unavailable or mismatched timing: ${response.body}',
        () async {
      final service = EndingTimingService(
          client: MockClient((request) async =>
              request.url.host == 'graphql.anilist.co'
                  ? titles([title()])
                  : response));
      addTearDown(service.close);
      expect(
          await service.fetchEnding(context(), const Duration(seconds: 1440)),
          isNull);
    });
  }

  test('does not guess special episodes or season number offsets', () async {
    var requests = 0;
    final service = EndingTimingService(client: MockClient((_) async {
      requests++;
      return titles([title()]);
    }));
    addTearDown(service.close);
    expect(
        await service.fetchEnding(
            context(number: '2.5'), const Duration(seconds: 1440)),
        isNull);
    expect(requests, 0);
    expect(
        await service.fetchEnding(
            context(number: '13'), const Duration(seconds: 1440)),
        isNull);
    expect(requests, 1);
  });
}
