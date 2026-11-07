import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/helpers/update_manager.dart';
import 'package:tako_play/services/request_service.dart';

void main() {
  RequestService serviceFor(http.Response Function() response) {
    return RequestService(client: MockClient((_) async => response()));
  }

  test('marks an equal release version as current', () async {
    final service = serviceFor(
      () => http.Response('{"tag_name":"v1.7.0","assets":[]}', 200),
    );
    final manager = UpdateManager(requestService: service);

    await manager.checkForUpdate();

    expect(manager.status, UpdateStatus.current);
    expect(manager.downloadLink, isNull);
    service.close();
  });

  test('publishes an update only when a usable download link exists', () async {
    final service = serviceFor(
      () => http.Response(
        '''{"tag_name":"v1.7.1","assets":[{"browser_download_url":"https://example.com/app.apk"}]}''',
        200,
      ),
    );
    final manager = UpdateManager(requestService: service);

    await manager.checkForUpdate();

    expect(manager.status, UpdateStatus.available);
    expect(manager.downloadLink, 'https://example.com/app.apk');
    service.close();
  });

  test('fails safely when the update endpoint returns an error', () async {
    final service = serviceFor(() => http.Response('unavailable', 503));
    final manager = UpdateManager(requestService: service);

    await manager.checkForUpdate();

    expect(manager.status, UpdateStatus.failed);
    expect(manager.downloadLink, isNull);
    service.close();
  });
}
