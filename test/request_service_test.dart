import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/utils/constants.dart';

void main() {
  group('RequestService', () {
    test('adds the required source headers to catalog requests', () async {
      late http.BaseRequest capturedRequest;
      final service = RequestService(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response('<html></html>', 200);
        }),
      );

      await service.requestPopularResponse();

      expect(capturedRequest.headers['referer'], referer);
      expect(capturedRequest.headers['user-agent'], userAgent);
      service.close();
    });

    test('turns non-success HTTP responses into a request error', () async {
      final service = RequestService(
        client: MockClient((_) async => http.Response('gone', 410)),
      );

      expect(
        service.requestMoviesResponse(),
        throwsA(
          isA<RequestException>().having(
            (error) => error.message,
            'message',
            contains('HTTP 410'),
          ),
        ),
      );
      service.close();
    });

    test('sends source headers and fields for episode range requests',
        () async {
      late http.BaseRequest capturedRequest;
      final service = RequestService(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      await service.postSource(
        Uri.parse('https://catalog.example.com/episodes'),
        body: {'nonce': 'one-time-token', 'range_start': '1'},
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.headers['referer'], referer);
      expect((capturedRequest as http.Request).bodyFields, {
        'nonce': 'one-time-token',
        'range_start': '1',
      });
      service.close();
    });

    test('turns request timeouts into a descriptive request error', () async {
      final service = RequestService(
        timeout: const Duration(milliseconds: 1),
        client: MockClient(
          (_) => Future<http.Response>.delayed(
            const Duration(milliseconds: 20),
            () => http.Response('', 200),
          ),
        ),
      );

      expect(
        service.requestRecentlyAddedResponse(),
        throwsA(isA<RequestException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        )),
      );
      service.close();
    });

    test('turns client failures into a descriptive request error', () async {
      final service = RequestService(
        client: MockClient((_) => throw http.ClientException('offline')),
      );

      expect(
        service.requestRecentlyAddedResponse(),
        throwsA(isA<RequestException>().having(
          (error) => error.message,
          'message',
          contains('Could not reach'),
        )),
      );
      service.close();
    });
  });
}
