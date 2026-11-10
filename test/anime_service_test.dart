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
    expect(anime.animeUrl, 'https://gogoanimes.org/category/hero');
    expect(anime.imageUrl, 'https://gogoanimes.org/images/hero.jpg');
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
      'https://gogoanimes.org/watch/episode-1',
      'https://gogoanimes.org/watch/episode-2',
      'https://gogoanimes.org/watch/episode-10',
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

  test('parses source movie cards with their supplied artwork', () async {
    const listing = '''
      <main><section><ul class="grid">
        <li class="group">
          <a href="/watch/movie-one-1/"><img src="https://img.example/movie-one.webp"></a>
          <span>Movie</span><span>Ep 1</span>
          <p><a href="/watch/movie-one-1/">Movie One</a></p>
        </li>
        <li class="group">
          <a href="/watch/movie-two-2/"><img src="https://img.example/movie-two.webp"></a>
          <span>Movie</span><span>Ep 1</span>
          <p><a href="/watch/movie-two-2/">Movie Two</a></p>
        </li>
      </ul></section></main>
    ''';
    final service = RequestService(
      client: MockClient((request) async {
        expect(request.url.path, '/movies/');
        return http.Response(listing, 200);
      }),
    );

    final movies = await AnimeService(requestService: service)
        .getMovies(service.requestMoviesResponse());

    expect(movies.animeList, hasLength(2));
    expect(
        movies.animeList.first.imageUrl, 'https://img.example/movie-one.webp');
    expect(movies.animeList.last.releasedDate, 'Movie');
    service.close();
  });

  test('parses source title details, episode controls, and embed handoff',
      () async {
    const markup = '''
      <section id="w-episodes">
        <button data-n="2" class="active">EP 2</button>
        <button data-n="1">EP 1</button>
      </section>
      <section id="info">
        <p><span class="text-note">Plot Summary:</span> A source synopsis.</p>
        <p><span class="text-note">Genre:</span><a href="/genre/action/">Action</a></p>
        <p><span class="text-note">Released:</span> 2026</p>
        <p><span class="text-note">Status:</span> Airing</p>
      </section>
      <button class="w-server" data-sv="2" aria-pressed="true">Server 2</button>
      <button class="w-lang" data-lang="sub" aria-pressed="true">Sub</button>
      <script>const playerHost = "https://play.gogoanimes.org", token = "abcdefghijklmnopqrstuvwxyz_1234567890-abcdef";</script>
    ''';
    final service = RequestService(
      client: MockClient((_) async => http.Response(markup, 200)),
    );
    final animeService = AnimeService(requestService: service);

    final anime =
        await animeService.fetchAnimeDetails('/watch/source-show-42/');
    final players = await animeService.fetchIframeEmbeds(
      'https://gogoanimes.org/watch/source-show-42/#episode=1',
    );

    expect(anime.id, '42');
    expect(anime.summary, 'A source synopsis.');
    expect(anime.genres.single.name, 'Action');
    expect(anime.episodes.map((episode) => episode.number), ['1', '2']);
    expect(anime.episodes.first.link, endsWith('#episode=1'));
    expect(players, [
      'https://play.gogoanimes.org/watch#abcdefghijklmnopqrstuvwxyz_1234567890-abcdef.1.2.sub',
    ]);
    service.close();
  });

  test('searches the source-published title index', () async {
    const index = '''
      [
        {"i": 1, "s": "bleach-1", "n": "Bleach", "e": 366},
        {"i": 2, "s": "other-2", "n": "Other title", "an": ["Bleach story"]}
      ]
    ''';
    final service = RequestService(
      client: MockClient((request) async {
        expect(request.url.path, '/filter-index.json');
        return http.Response(index, 200);
      }),
    );

    final results =
        await AnimeService(requestService: service).searchAnimes('bleach');

    expect(results.animeList.map((anime) => anime.name),
        ['Bleach', 'Other title']);
    expect(results.animeList.first.imageUrl,
        'https://img.gogoanimes.org/poster-sm/w_200/h_267/bleach-1.webp');
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

    expect(requestedUri.host, 'gogoanimes.org');
    expect(requestedUri.path, '/category/legacy-title');
    service.close();
  });
}
