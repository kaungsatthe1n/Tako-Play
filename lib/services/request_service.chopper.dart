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
  Future<Response<dynamic>> fetchHomePage() {
    final $url = 'https://gogoplay1.com/';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestSearchResponse(String name) {
    final $url = 'https://gogoplay1.com//search.html?keyword=${name}';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestEpisodeResponse(String path) {
    final $url = 'https://gogoplay1.com/${path}';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestPopularResponse() {
    final $url = 'https://gogoplay1.com/popular';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> requestOnGoingResponse() {
    final $url = 'https://gogoplay1.com/ongoing-series';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestActualVideoResponse(String url) {
    final $url = url;
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestEmbededResponse(String url) {
    final $url = 'https:$url';
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response> requestGitHubUpdate(String url) {
    final $url = url;
    final $request = Request('GET', $url, '');
    return client.send<dynamic, dynamic>($request);
  }
}
