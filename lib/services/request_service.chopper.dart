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
    final $url = Uri.parse('https://gogoanime.wiki/search.html?keyword=$name');
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestAnimeDetailResponse(String path) {
    final $url = Uri.parse('https://gogoanime.wiki$path');
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestAnimeCdn(String url) {
    final $url = Uri.parse(url);
    final $request = Request('GET', $url, Uri.parse(''));
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestAnimeData(
      String host, String encryptedId, String encryptAjaxParams, String id) {
    final $url = Uri.parse(
        '${host}encrypt-ajax.php?id=$encryptedId$encryptAjaxParams&alias=$id');
    String a1 = 'X-Requested-With';
    String a2 = 'XMLHttpRequest';
    final $request = Request('GET', $url, Uri.parse(''), headers: {a1: a2});
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestPopularResponse() {
    final $url = Uri.parse('https://gogoanime.wiki/popular.html');
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestMoviesResponse() {
    final $url = Uri.parse('https://gogoanime.wiki/anime-movies.html');
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestAnimeGenre(String url, [int index = 1]) {
    final $url = Uri.parse('$url?page=$index');
    final $request = Request('GET', $url, Uri.parse(''));
    return client.send<dynamic, dynamic>($request);
  }

  /// Not Concern with BaseUrl //
  @override
  Future<Response> requestCdnVideoLink(String url) {
    final $url = Uri.parse(url);
    final $request = Request('GET', $url, Uri.parse(''));
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestEpisodesResponse(String id) {
    final $url = Uri.parse(
        'https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=5000&id=$id');
    final $request = Request('GET', $url, Uri.parse(''));
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestGitHubUpdate(String url) {
    final $url = Uri.parse(url);
    final $request = Request('GET', $url, Uri.parse(''));
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestRecentlyAddedResponse() {
    final $url =
        Uri.parse('https://ajax.gogocdn.net/ajax/page-recent-release.html');
    final $request = Request('GET', $url, Uri.parse(''));
    return client.send<dynamic, dynamic>($request);
  }
}
