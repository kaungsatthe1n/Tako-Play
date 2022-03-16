// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations
class _$RequestService extends RequestService {
  _$RequestService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = RequestService;

  @override
  Future<Response<dynamic>> requestSearchResponse(String name) {
    final $url = 'https://gogoanime.wiki//search.html?keyword=$name';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestAnimeDetailResponse(String path) {
    final $url = 'https://gogoanime.wiki/$path';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestPopularResponse() {
    final $url = 'https://gogoanime.wiki/popular.html';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestMoviesResponse() {
    final $url = 'https://gogoanime.wiki/anime-movies.html';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestAnimeGenre(String url, [int index = 1]) {
    final $url = url+'?page=$index';
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }

  /// Not Concern with BaseUrl //
  @override
  Future<Response> requestCdnVideoLink(String url) {
    final $url = 'https:' + url;
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestEpisodesResponse(String id) {
    final $url =
        'https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=5000&id=$id';
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestGitHubUpdate(String url) {
    final $url = url;
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestRecentlyAddedResponse() {
    final $url = 'https://ajax.gogocdn.net/ajax/page-recent-release.html';
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }
}
