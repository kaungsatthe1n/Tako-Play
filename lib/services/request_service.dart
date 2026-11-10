import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// The single HTTP boundary for catalog and metadata requests.
///
/// Keeping timeouts, source headers, status validation, and error messages in
/// one place prevents individual screens from hanging or interpreting failed
/// HTML responses as valid content.
class RequestService extends GetxService {
  RequestService({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15);

  factory RequestService.create() => RequestService();

  final http.Client _client;
  final Duration _timeout;

  Future<http.Response> requestRecentlyAddedResponse() =>
      getSource(Uri.parse(baseUrl));

  Future<http.Response> requestSearchResponse(String name) {
    final uri = Uri.parse('$sourceBaseUrl/search/')
        .replace(queryParameters: {'keyword': name});
    return getSource(uri);
  }

  Future<http.Response> requestSearchIndexResponse() =>
      getSource(Uri.parse('$sourceBaseUrl/filter-index.json'));

  Future<http.Response> requestAnimeDetailResponse(String path) =>
      getSource(Uri.parse(baseUrl).resolve(path));

  Future<http.Response> requestPopularResponse() =>
      getSource(Uri.parse('$sourceBaseUrl/popular/'));

  Future<http.Response> requestMoviesResponse() =>
      getSource(Uri.parse('$sourceBaseUrl/movies/'));

  Future<http.Response> requestAnimeGenre(String url, [int index = 1]) {
    final genre = Uri.parse(url).replace(
      path: Uri.parse(url).path.replaceFirst('/genres/', '/genre/'),
    );
    final normalizedUrl = genre.toString();
    final page = index == 1
        ? normalizedUrl
        : '${normalizedUrl.endsWith('/') ? normalizedUrl : '$normalizedUrl/'}page/$index/';
    return getSource(Uri.parse(page));
  }

  Future<http.Response> requestGitHubUpdate(String url) => _get(
        Uri.parse(url),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

  Future<http.Response> requestCdnVideoLink(String url) => _get(Uri.parse(url));

  Future<http.Response> getSource(Uri uri) => _get(uri, sourceRequest: true);

  Future<http.Response> postSource(
    Uri uri, {
    required Map<String, String> body,
  }) =>
      _send(
        () => _client.post(uri, headers: _sourceHeaders, body: body),
        uri,
      );

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
    bool sourceRequest = false,
  }) =>
      _send(
        () => _client.get(
          uri,
          headers: {
            if (sourceRequest) ..._sourceHeaders,
            ...?headers,
          },
        ),
        uri,
      );

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RequestException.httpStatus(uri, response.statusCode);
      }
      return response;
    } on TimeoutException {
      throw RequestException.timeout(uri, _timeout);
    } on SocketException catch (error) {
      throw RequestException.network(uri, error.message);
    } on http.ClientException catch (error) {
      throw RequestException.network(uri, error.message);
    }
  }

  Map<String, String> get _sourceHeaders => {
        ...header,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      };

  @override
  void onClose() {
    close();
    super.onClose();
  }

  void close() => _client.close();
}

class RequestException implements Exception {
  const RequestException._(this.message);

  factory RequestException.timeout(Uri uri, Duration timeout) =>
      RequestException._(
          'Request to ${uri.host} timed out after ${timeout.inSeconds}s.');

  factory RequestException.network(Uri uri, String message) =>
      RequestException._('Could not reach ${uri.host}: $message');

  factory RequestException.httpStatus(Uri uri, int statusCode) =>
      RequestException._('${uri.host} returned HTTP $statusCode.');

  final String message;

  @override
  String toString() => message;
}
