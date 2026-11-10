import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/anime.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';

/// Parses the public catalogue served by gogoanimes.org.
///
/// Catalogue pages are static HTML card grids. Its search index is published
/// separately as JSON, while title metadata and episode controls are embedded
/// in each `/watch/` page.
class AnimeService {
  AnimeService({required RequestService requestService})
      : _requestService = requestService;

  static const _episodeRangeConcurrency = 4;
  static const _legacyCatalogHosts = <String>{
    'gogoanime9.ro',
    'www.gogoanime9.ro',
    'gogoanime.wiki',
    'www.gogoanime.wiki',
  };

  final RequestService _requestService;
  final _uuid = const Uuid();
  Future<List<_SearchEntry>>? _searchIndex;

  Future<AnimeResults> getAnimes(Future<http.Response> request) async {
    final response = await request;
    return _parseImageCards(parse(response.body));
  }

  Future<AnimeResults> getRecentlyAddedAnimes() =>
      getAnimes(_requestService.requestRecentlyAddedResponse());

  Future<AnimeResults> getMovies(Future<http.Response> request) async {
    final response = await request;
    return _parseImageCards(parse(response.body));
  }

  Future<AnimeResults> searchAnimes(String query) async {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return const AnimeResults(animeList: <Anime>[]);
    }

    final searchIndex = await _loadSearchIndex();
    final terms = normalizedQuery.split(' ');
    final matches = <_SearchEntry>[];
    for (final entry in searchIndex) {
      if (entry.searchRank(normalizedQuery, terms) >= 0) {
        matches.add(entry);
      }
    }
    matches.sort((left, right) {
      final rank = left
          .searchRank(normalizedQuery, terms)
          .compareTo(right.searchRank(normalizedQuery, terms));
      if (rank != 0) return rank;
      return left.name.length.compareTo(right.name.length);
    });

    return AnimeResults(
      animeList: matches
          .take(60)
          .map(
            (entry) => Anime(
              id: entry.id,
              name: entry.name,
              animeUrl: _watchUrl(entry.slug),
              imageUrl: _posterUrl(entry.slug),
              currentEp:
                  entry.episodeCount == null ? '' : 'Ep ${entry.episodeCount}',
              releasedDate: entry.isMovie ? 'Movie' : '',
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<_SearchEntry>> _loadSearchIndex() async {
    try {
      return await (_searchIndex ??= _fetchSearchIndex());
    } catch (_) {
      _searchIndex = null;
      rethrow;
    }
  }

  Future<List<_SearchEntry>> _fetchSearchIndex() async {
    final response = await _requestService.requestSearchIndexResponse();
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('The source search index is invalid.');
    }
    return decoded
        .whereType<Map>()
        .map(_SearchEntry.fromJson)
        .whereType<_SearchEntry>()
        .toList(growable: false);
  }

  Future<Anime> fetchAnimeDetails(String url) async {
    final detailDoc = await _fetchDocument(url);
    final sourceInfo = detailDoc.querySelector('#info');
    if (sourceInfo != null) {
      return _parseGogoAnimesDetails(detailDoc, sourceInfo, url);
    }

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
  /// gogoanimes.org advertises the selected episode, language, and server in
  /// its page controls and constructs an external player handoff in its page
  /// script. Older catalog pages can instead expose pre-rendered iframes in
  /// `data-video`, which remain supported as a compatibility fallback.
  Future<List<String>> fetchIframeEmbeds(String url) async {
    final document = await _fetchDocument(url);
    if (document.querySelector('#w-episodes') != null) {
      final embeds = _sourcePlayerEmbeds(document, url);
      if (embeds.isNotEmpty) return embeds;
    }

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
    final sourceCards = _parseGogoAnimesCards(document);
    if (sourceCards.isNotEmpty) {
      return AnimeResults(animeList: sourceCards);
    }

    // Keep legacy parsing for saved staging fixtures and deployments that use
    // the former WordPress-compatible markup.
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

  List<Anime> _parseGogoAnimesCards(dom.Document document) {
    final cards = <Anime>[];
    final seenUrls = <String>{};

    for (final item in document.querySelectorAll('main section ul.grid > li')) {
      final links = item
          .querySelectorAll('a[href]')
          .where((link) => link.text.trim().isNotEmpty)
          .toList(growable: false);
      if (links.isEmpty) continue;

      final nameLink = links.last;
      final url = _absoluteUrl(nameLink.attributes['href']);
      final name = nameLink.text.trim();
      if (name.isEmpty || url.isEmpty || !seenUrls.add(url)) continue;

      final image = item.querySelector('img[src]');
      final label = item
          .querySelectorAll('span')
          .map((element) => element.text.trim())
          .firstWhere(
            (text) => text.toLowerCase().startsWith('ep '),
            orElse: () => '',
          );
      final isMovie = item.querySelectorAll('span').any(
            (element) => element.text.trim().toLowerCase() == 'movie',
          );

      cards.add(Anime(
        id: _sourceId(url),
        name: name,
        animeUrl: url,
        imageUrl: _absoluteUrl(image?.attributes['src']),
        currentEp: label,
        releasedDate: isMovie ? 'Movie' : label,
      ));
    }
    return cards;
  }

  Future<dom.Document> _fetchDocument(String url) async {
    final response = await _requestService.getSource(
      Uri.parse(_absoluteUrl(url)),
    );
    return parse(response.body);
  }

  Anime _parseGogoAnimesDetails(
    dom.Document document,
    dom.Element info,
    String url,
  ) {
    final genres = <Genre>[];
    var summary = '';
    var released = '';
    var status = '';

    for (final paragraph in info.querySelectorAll('p')) {
      final label = paragraph.querySelector('.text-note')?.text.trim() ?? '';
      final value = paragraph.text.replaceFirst(label, '').trim();
      switch (label.toLowerCase()) {
        case 'plot summary:':
          summary = value;
          break;
        case 'genre:':
          for (final link in paragraph.querySelectorAll('a[href]')) {
            final name = link.text.trim();
            if (name.isNotEmpty) {
              genres.add(Genre(
                name: name,
                link: _absoluteUrl(link.attributes['href']),
              ));
            }
          }
          break;
        case 'released:':
          released = value;
          break;
        case 'status:':
          status = value;
          break;
      }
    }

    final byNumber = <String, Episode>{};
    for (final button
        in document.querySelectorAll('#w-episodes button[data-n]')) {
      final number = button.attributes['data-n']?.trim() ?? '';
      if (number.isEmpty) continue;
      byNumber[number] = Episode(
        link: _episodeUrl(url, number),
        number: number,
      );
    }
    final episodes = byNumber.values.toList()
      ..sort((a, b) => (double.tryParse(a.number) ?? 0)
          .compareTo(double.tryParse(b.number) ?? 0));

    return Anime(
      id: _sourceId(url),
      summary: summary,
      genres: genres,
      releasedDate: released,
      status: status,
      episodes: episodes,
    );
  }

  List<String> _sourcePlayerEmbeds(dom.Document document, String url) {
    final script = document
        .querySelectorAll('script')
        .map((element) => element.text)
        .firstWhere(
          (value) => value.contains('play.gogoanimes.org'),
          orElse: () => '',
        );
    final host =
        RegExp(r'https://play\.gogoanimes\.org').firstMatch(script)?.group(0);
    final token = RegExp(r'''['"]([A-Za-z0-9_-]{32,})['"]''')
        .allMatches(script)
        .map((match) => match.group(1))
        .firstWhere((value) => value != null, orElse: () => null);
    if (host == null || token == null) return const <String>[];

    final requestedEpisode = RegExp(r'(?:^|[&;])episode=(\d+(?:\.\d+)?)')
            .firstMatch(Uri.tryParse(url)?.fragment ?? '')
            ?.group(1) ??
        document
            .querySelector('#w-episodes button.active[data-n]')
            ?.attributes['data-n'] ??
        document
            .querySelector('#w-episodes button[data-n]')
            ?.attributes['data-n'];
    if (requestedEpisode == null || requestedEpisode.isEmpty) {
      return const <String>[];
    }

    final server = document
            .querySelector('.w-server[aria-pressed="true"][data-sv]')
            ?.attributes['data-sv'] ??
        document.querySelector('.w-server[data-sv]')?.attributes['data-sv'];
    final language = document
            .querySelector('.w-lang[aria-pressed="true"][data-lang]')
            ?.attributes['data-lang'] ??
        document.querySelector('.w-lang[data-lang]')?.attributes['data-lang'];
    if (server == null || language == null) return const <String>[];

    // This is the external player URL explicitly constructed by the source
    // page for the selected episode. It remains an embed handoff; no media
    // stream URL is read or constructed by the app.
    return ['$host/watch#$token.$requestedEpisode.$server.$language'];
  }

  String _episodeUrl(String sourceUrl, String episodeNumber) {
    final uri = Uri.parse(_absoluteUrl(sourceUrl));
    return uri.replace(fragment: 'episode=$episodeNumber').toString();
  }

  String _watchUrl(String slug) => '$sourceBaseUrl/watch/$slug/';

  String _posterUrl(String slug) =>
      'https://img.gogoanimes.org/poster-sm/w_200/h_267/$slug.webp';

  String _sourceId(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final segment = segments.lastWhere(
      (value) => value.isNotEmpty,
      orElse: () => url,
    );
    return RegExp(r'-(\d+)$').firstMatch(segment)?.group(1) ?? segment;
  }

  String _normalizeSearchText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

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

class _SearchEntry {
  const _SearchEntry({
    required this.id,
    required this.slug,
    required this.name,
    required this.names,
    required this.episodeCount,
    required this.isMovie,
  });

  final String id;
  final String slug;
  final String name;
  final List<String> names;
  final int? episodeCount;
  final bool isMovie;

  static _SearchEntry? fromJson(Map<dynamic, dynamic> json) {
    final id = json['i'];
    final slug = json['s'];
    final name = json['n'];
    if (id == null || slug is! String || slug.isEmpty || name is! String) {
      return null;
    }

    final names = <String>[name];
    final japaneseName = json['j'];
    if (japaneseName is String && japaneseName.isNotEmpty) {
      names.add(japaneseName);
    }
    final aliases = json['an'];
    if (aliases is List) {
      names.addAll(
          aliases.whereType<String>().where((alias) => alias.isNotEmpty));
    }

    return _SearchEntry(
      id: id.toString(),
      slug: slug,
      name: name,
      names: names,
      episodeCount: (json['e'] as num?)?.toInt(),
      isMovie: json['m'] == 1 || json['m'] == true,
    );
  }

  int searchRank(String normalizedQuery, List<String> terms) {
    final normalizedNames = names
        .map(
          (name) =>
              name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim(),
        )
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (normalizedNames.isEmpty) return -1;

    final primary = normalizedNames.first;
    if (primary.startsWith(normalizedQuery)) return 0;
    if (primary.contains(' $normalizedQuery')) return 1;
    if (primary.contains(normalizedQuery)) return 2;
    if (normalizedNames.skip(1).any((name) => name.contains(normalizedQuery))) {
      return 3;
    }
    if (normalizedNames.any(
      (name) => terms.every((term) => name.contains(term)),
    )) {
      return 4;
    }
    return -1;
  }
}
