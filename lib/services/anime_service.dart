import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/anime.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';

/// Parses the public catalog served by gogoanime9.ro.
///
/// The source is a WordPress site: catalogue pages are normal HTML, while an
/// anime's episode list is returned by its WordPress AJAX endpoint.
class AnimeService {
  AnimeService({required RequestService requestService})
      : _requestService = requestService;

  static const _moviePosterConcurrency = 6;
  static const _episodeRangeConcurrency = 4;
  static const _legacyCatalogHosts = <String>{
    'gogoanime.wiki',
    'www.gogoanime.wiki',
  };

  final RequestService _requestService;
  final _uuid = const Uuid();

  Future<AnimeResults> getAnimes(Future<http.Response> request) async {
    final response = await request;
    return _parseImageCards(parse(response.body));
  }

  Future<AnimeResults> getRecentlyAddedAnimes() =>
      getAnimes(_requestService.requestRecentlyAddedResponse());

  Future<AnimeResults> getMovies(Future<http.Response> request) async {
    final response = await request;
    final document = parse(response.body);
    final movieLinks = <({String name, String url})>[];

    for (final item in document.querySelectorAll('ul.listing > li')) {
      final link = item.querySelector('a[href]');
      if (link == null) continue;

      final name = link.text.trim();
      if (name.isEmpty) continue;
      movieLinks.add((
        name: name,
        url: _absoluteUrl(link.attributes['href']),
      ));
    }

    // The movie index is text-only. Detail pages include a real poster in
    // `.anime_info_body_bg`, so enrich each card before returning the list.
    final movies = await _mapConcurrent(movieLinks, (movie) async {
      final imageUrl = await _fetchMoviePoster(movie.url);
      return Anime(
        id: _uuid.v4(),
        name: movie.name,
        animeUrl: movie.url,
        imageUrl: imageUrl,
        releasedDate: 'Movie',
      );
    }, maxConcurrent: _moviePosterConcurrency);

    return AnimeResults(animeList: movies);
  }

  Future<Anime> fetchAnimeDetails(String url) async {
    final detailDoc = await _fetchDocument(url);
    final info = detailDoc.querySelector('.anime_info_body_bg');
    if (info == null) {
      throw StateError('The anime details were not found in the source page.');
    }

    final genres = <Genre>[];
    var summary = info.querySelector('.description')?.text.trim() ?? '';
    var released = '';
    var status = '';

    for (final type in info.querySelectorAll('p.type')) {
      final label = type.text.trim();
      if (label.startsWith('Genres:')) {
        for (final link in type.querySelectorAll('a[href]')) {
          final name = link.text.trim();
          if (name.isNotEmpty) {
            genres.add(Genre(
              name: name,
              link: _absoluteUrl(link.attributes['href']),
            ));
          }
        }
      } else if (label.startsWith('Released:')) {
        released = label.replaceFirst('Released:', '').trim();
      } else if (label.startsWith('Status:')) {
        status = label.replaceFirst('Status:', '').trim();
      }
    }

    // Some pages put synopsis in a labelled paragraph instead of description.
    if (summary.isEmpty) {
      final synopsis = info.querySelectorAll('p.type').where(
            (element) => element.text.trim().startsWith('Synopsis:'),
          );
      if (synopsis.isNotEmpty) {
        summary = synopsis.first.text.replaceFirst('Synopsis:', '').trim();
      }
    }

    final seriesId = detailDoc.querySelector('#movie_id')?.attributes['value'];
    final episodes = seriesId == null
        ? <Episode>[]
        : await _loadEpisodes(detailDoc, seriesId);

    return Anime(
      id: seriesId ?? _uuid.v4(),
      summary: summary,
      genres: genres,
      releasedDate: released,
      status: status,
      episodes: episodes,
    );
  }

  /// Returns every distinct HTTPS player advertised by an episode page.
  ///
  /// gogoanime9 stores HTML iframes in `data-video`, unlike the retired
  /// `.play-video` markup used by the old provider. A server can retire an
  /// individual embed without the episode itself disappearing, so callers can
  /// retry the next source-provided player after an HTTP 410 response.
  Future<List<String>> fetchIframeEmbeds(String url) async {
    final document = await _fetchDocument(url);
    final players = <String>[];
    for (final server
        in document.querySelectorAll('.anime_muti_link a[data-video]')) {
      final rawEmbed = server.attributes['data-video'];
      if (rawEmbed == null || rawEmbed.isEmpty) continue;
      final src = parseFragment(rawEmbed)
          .querySelector('iframe[src]')
          ?.attributes['src'];
      if (src == null || src.isEmpty) continue;
      final playerUrl = _absoluteUrl(src);
      final playerUri = Uri.tryParse(playerUrl);
      if (playerUri != null &&
          playerUri.scheme == 'https' &&
          playerUri.host.isNotEmpty &&
          !players.contains(playerUrl)) {
        players.add(playerUrl);
      }
    }
    if (players.isNotEmpty) {
      // Preserve the provider's order. It is the only reliable indication of
      // its currently supported servers; do not hard-code player hosts here.
      return players;
    }

    // Keep a small fallback for pages whose server markup is rendered inline.
    final fallback = document.querySelector('.play-video iframe[src]');
    final src = fallback?.attributes['src'];
    if (src != null && src.isNotEmpty) {
      final playerUrl = _absoluteUrl(src);
      final playerUri = Uri.tryParse(playerUrl);
      if (playerUri != null &&
          playerUri.scheme == 'https' &&
          playerUri.host.isNotEmpty) {
        return [playerUrl];
      }
    }

    throw StateError('No playable video embed was found for this episode.');
  }

  /// Returns the first player offered on an episode page.
  ///
  /// Kept for existing callers. New playback code should use
  /// [fetchIframeEmbeds] so it can recover when one advertised server returns
  /// HTTP 410.
  Future<String> fetchIframeEmbedded(String url) async =>
      (await fetchIframeEmbeds(url)).first;

  // Retained for source compatibility with callers using the previous CDN.
  Future<Map<String, String>> fetchCdnStreamLink(String url) async {
    final response = await _requestService.requestCdnVideoLink(url);
    final doc = parse(response.body);
    final streams = <String, String>{};
    for (final link in doc.querySelectorAll('.mirror_link .dowload a[href]')) {
      final match = resolutionRegExp.firstMatch(link.text);
      final href = link.attributes['href'];
      if (match != null && href != null) streams[match.group(0)!] = href;
    }
    return streams;
  }

  Future<Map<String, String>> getVideoWithResolution(String url) async {
    final iframeEmbedded = await fetchIframeEmbedded(url);
    return fetchCdnStreamLink(iframeEmbedded);
  }

  Future<AnimeResults> _parseImageCards(dom.Document document) async {
    final animeList = <Anime>[];

    for (final item in document.querySelectorAll('ul.items > li')) {
      final nameLink = item.querySelector('.name a[href]');
      if (nameLink == null) continue;
      final name = nameLink.text.trim();
      if (name.isEmpty) continue;

      final image = item.querySelector('.img img');
      animeList.add(Anime(
        id: _uuid.v4(),
        name: name,
        animeUrl: _absoluteUrl(nameLink.attributes['href']),
        imageUrl: _absoluteUrl(
          image?.attributes['data-src'] ?? image?.attributes['src'],
        ),
        currentEp: item.querySelector('.episode')?.text.trim() ?? '',
        releasedDate: item.querySelector('.released')?.text.trim() ??
            item.querySelector('.episode')?.text.trim() ??
            '',
      ));
    }
    return AnimeResults(animeList: animeList);
  }

  Future<dom.Document> _fetchDocument(String url) async {
    final response = await _requestService.getSource(
      Uri.parse(_absoluteUrl(url)),
    );
    return parse(response.body);
  }

  Future<String> _fetchMoviePoster(String url) async {
    try {
      final document = await _fetchDocument(url);
      final image = document.querySelector('.anime_info_body_bg img');
      return _absoluteUrl(
          image?.attributes['data-src'] ?? image?.attributes['src']);
    } catch (_) {
      // One removed title must not prevent the movie rail from rendering.
      return '';
    }
  }

  Future<List<Episode>> _loadEpisodes(
    dom.Document detailDoc,
    String seriesId,
  ) async {
    final script = detailDoc
        .querySelectorAll('script')
        .map((element) => element.text)
        .join();
    final nonce =
        RegExp(r'''nonce\s*:\s*['"]([^'"]+)''').firstMatch(script)?.group(1);
    final ranges =
        detailDoc.querySelectorAll('a[data-range-start][data-range-end]');
    if (nonce == null || ranges.isEmpty) return <Episode>[];

    final chunks = await _mapConcurrent(ranges, (range) async {
      final response = await _requestService.postSource(
        Uri.parse('$sourceBaseUrl/wp-admin/admin-ajax.php'),
        body: {
          'action': 'load_episode_range',
          'range_start': range.attributes['data-range-start']!,
          'range_end': range.attributes['data-range-end']!,
          'seri_id': seriesId,
          'nonce': nonce,
        },
      );
      final payload = jsonDecode(response.body);
      if (payload is! Map ||
          payload['success'] != true ||
          payload['data'] is! String) {
        return <Episode>[];
      }

      final episodeDoc = parseFragment(payload['data'] as String);
      return episodeDoc.querySelectorAll('li a[href]').map((link) {
        final text =
            link.querySelector('.name')?.text.trim() ?? link.text.trim();
        final number =
            RegExp(r'(\d+(?:\.\d+)?)\s*$').firstMatch(text)?.group(1) ??
                text
                    .replaceFirst(RegExp(r'^EP\s*', caseSensitive: false), '')
                    .trim();
        return Episode(
          link: _absoluteUrl(link.attributes['href']),
          number: number,
        );
      }).toList();
    }, maxConcurrent: _episodeRangeConcurrency);

    final byLink = <String, Episode>{};
    for (final chunk in chunks) {
      for (final episode in chunk) {
        byLink[episode.link] = episode;
      }
    }
    final episodes = byLink.values.toList()
      ..sort((a, b) => (double.tryParse(a.number) ?? 0)
          .compareTo(double.tryParse(b.number) ?? 0));
    return episodes;
  }

  String _absoluteUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    final resolved = Uri.parse(baseUrl).resolve(value);
    if (!_legacyCatalogHosts.contains(resolved.host.toLowerCase())) {
      return resolved.toString();
    }

    final source = Uri.parse(sourceBaseUrl);
    return source
        .replace(
          path: resolved.path,
          query: resolved.hasQuery ? resolved.query : null,
          fragment: resolved.hasFragment ? resolved.fragment : null,
        )
        .toString();
  }

  Future<List<T>> _mapConcurrent<S, T>(
    Iterable<S> values,
    Future<T> Function(S value) mapper, {
    required int maxConcurrent,
  }) async {
    final items = values.toList(growable: false);
    final results = <T>[];
    for (var index = 0; index < items.length; index += maxConcurrent) {
      final end = index + maxConcurrent > items.length
          ? items.length
          : index + maxConcurrent;
      results.addAll(await Future.wait(
        items.sublist(index, end).map(mapper),
      ));
    }
    return results;
  }
}
