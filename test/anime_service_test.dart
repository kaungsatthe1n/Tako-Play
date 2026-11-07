import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/services/anime_service.dart';
import 'package:tako_play/services/request_service.dart';

void main() {
  late RequestService requestService;
  late AnimeService animeService;

  setUp(() {
    requestService = RequestService(
      client: MockClient((_) async => http.Response('', 200)),
    );
    animeService = AnimeService(requestService: requestService);
  });

  tearDown(() => requestService.close());

  test('parses catalog cards and resolves relative artwork URLs', () async {
    const markup = '''
      <ul class="items">
        <li>
          <div class="img"><img data-src="/images/hero.jpg"></div>
          <p class="name"><a href="/category/hero">Hero Show</a></p>
          <p class="episode">EP 8</p>
          <p class="released">Released: 2026</p>
        </li>
        <li><p class="name">Malformed item</p></li>
      </ul>
    ''';

    final results = await animeService.getAnimes(
      Future.value(http.Response(markup, 200)),
    );

    expect(results.animeList, hasLength(1));
    final anime = results.animeList.single;
    expect(anime.name, 'Hero Show');
    expect(anime.animeUrl, 'https://gogoanime9.ro/category/hero');
    expect(anime.imageUrl, 'https://gogoanime9.ro/images/hero.jpg');
    expect(anime.currentEp, 'EP 8');
  });

  test('ignores incomplete cards instead of failing the full catalog',
      () async {
    const markup = '<ul class="items"><li><div class="img"></div></li></ul>';

    final results = await animeService.getAnimes(
      Future.value(http.Response(markup, 200)),
    );

    expect(results.animeList, isEmpty);
  });

  test('loads, deduplicates, and numerically orders episode ranges', () async {
    const detailMarkup = '''
      <div class="anime_info_body_bg">
        <p class="description">A show about tests.</p>
        <p class="type">Released: 2026</p>
        <p class="type">Status: Ongoing</p>
      </div>
      <input id="movie_id" value="series-1">
      <script>const episodeData = { nonce: 'episode-token' };</script>
      <a data-range-start="1" data-range-end="3">1-3</a>
      <a data-range-start="4" data-range-end="5">4-5</a>
    ''';
    const firstRange = '''
      <li><a href="/watch/episode-2"><span class="name">EP 2</span></a></li>
      <li><a href="/watch/episode-1"><span class="name">EP 1</span></a></li>
    ''';
    const secondRange = '''
      <li><a href="/watch/episode-2"><span class="name">EP 2</span></a></li>
      <li><a href="/watch/episode-10"><span class="name">EP 10</span></a></li>
    ''';
    final calls = <http.BaseRequest>[];
    final service = RequestService(
      client: MockClient((request) async {
        calls.add(request);
        if (request.method == 'GET') {
          return http.Response(detailMarkup, 200);
        }
        final body = request.body;
        final isFirstRange = body.contains('range_start=1');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': isFirstRange ? firstRange : secondRange,
          }),
          200,
        );
      }),
    );
    final parsedService = AnimeService(requestService: service);

    final anime = await parsedService.fetchAnimeDetails('/anime/test');

    expect(calls.where((request) => request.method == 'POST'), hasLength(2));
    expect(anime.id, 'series-1');
    expect(anime.episodes.map((episode) => episode.number), ['1', '2', '10']);
    expect(anime.episodes.map((episode) => episode.link), [
      'https://gogoanime9.ro/watch/episode-1',
      'https://gogoanime9.ro/watch/episode-2',
      'https://gogoanime9.ro/watch/episode-10',
    ]);
    service.close();
  });

  test('returns an empty episode list when the source omits an AJAX nonce',
      () async {
    const markup = '''
      <div class="anime_info_body_bg"></div>
      <input id="movie_id" value="series-1">
      <a data-range-start="1" data-range-end="3">1-3</a>
    ''';
    final service = RequestService(
      client: MockClient((_) async => http.Response(markup, 200)),
    );

    final anime = await AnimeService(requestService: service)
        .fetchAnimeDetails('/anime/test');

    expect(anime.episodes, isEmpty);
    service.close();
  });

  test('preserves every source-provided iframe player in order', () async {
    const markup = '''
      <div class="anime_muti_link">
        <a data-video="&lt;iframe src='https://gogoanime.me.uk/embed/1'&gt;&lt;/iframe&gt;">HD-2</a>
        <a data-video="&lt;iframe src='//megaplay.buzz/stream/mal/1'&gt;&lt;/iframe&gt;">HD-1</a>
      </div>
    ''';
    final service = RequestService(
      client: MockClient((_) async => http.Response(markup, 200)),
    );

    final players = await AnimeService(requestService: service)
        .fetchIframeEmbeds('/episode/test');

    expect(players, [
      'https://gogoanime.me.uk/embed/1',
      'https://megaplay.buzz/stream/mal/1',
    ]);
    service.close();
  });

  test('enriches movie cards without letting one poster failure stop the rail',
      () async {
    const listing = '''
      <ul class="listing">
        <li><a href="/movie/one">Movie One</a></li>
        <li><a href="/movie/two">Movie Two</a></li>
      </ul>
    ''';
    final service = RequestService(
      client: MockClient((request) async {
        if (request.url.path == '/movies/') return http.Response(listing, 200);
        if (request.url.path == '/movie/one') {
          return http.Response(
              '<div class="anime_info_body_bg"><img src="/one.jpg"></div>',
              200);
        }
        return http.Response('gone', 410);
      }),
    );

    final movies = await AnimeService(requestService: service)
        .getMovies(service.requestMoviesResponse());

    expect(movies.animeList, hasLength(2));
    expect(movies.animeList.first.imageUrl, 'https://gogoanime9.ro/one.jpg');
    expect(movies.animeList.last.imageUrl, isEmpty);
    service.close();
  });

  test('rewrites legacy saved catalog URLs to the configured source', () async {
    late Uri requestedUri;
    final service = RequestService(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('<div class="anime_info_body_bg"></div>', 200);
      }),
    );

    await AnimeService(requestService: service).fetchAnimeDetails(
      'https://gogoanime.wiki/category/legacy-title',
    );

    expect(requestedUri.host, 'gogoanime9.ro');
    expect(requestedUri.path, '/category/legacy-title');
    service.close();
  });
}
