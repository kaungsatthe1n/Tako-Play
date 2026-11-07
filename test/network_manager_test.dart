import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/helpers/network_manager.dart';

void main() {
  test('does not probe the source when every interface is offline', () async {
    var calls = 0;
    final manager = NetworkManager(
      client: MockClient((_) async {
        calls++;
        return http.Response('', 200);
      }),
      sourceUri: Uri.parse('https://catalog.example.com'),
    );

    await manager.updateConnectionState([ConnectivityResult.none]);

    expect(manager.isOnline, isFalse);
    expect(calls, 0);
  });

  test('requires the catalog source to be reachable on an active interface',
      () async {
    final manager = NetworkManager(
      client: MockClient((_) async => http.Response('', 204)),
      sourceUri: Uri.parse('https://catalog.example.com'),
    );

    await manager.updateConnectionState([ConnectivityResult.wifi]);

    expect(manager.isOnline, isTrue);
  });

  test('treats source failures as offline', () async {
    final manager = NetworkManager(
      client: MockClient((_) async => http.Response('', 503)),
      sourceUri: Uri.parse('https://catalog.example.com'),
    );

    await manager.updateConnectionState([ConnectivityResult.mobile]);

    expect(manager.isOnline, isFalse);
  });
}
