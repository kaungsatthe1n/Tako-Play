import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
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

  test('starts from the platform check and responds to connectivity events',
      () async {
    final previous = ConnectivityPlatform.instance;
    final platform = _ConnectivityPlatform();
    ConnectivityPlatform.instance = platform;
    addTearDown(() {
      ConnectivityPlatform.instance = previous;
      platform.close();
    });
    final manager = NetworkManager(
      client: MockClient((_) async => http.Response('', 200)),
    );

    manager.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(manager.isOnline, isTrue);

    platform.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    expect(manager.isOnline, isFalse);
    manager.onClose();
  });
}

class _ConnectivityPlatform extends ConnectivityPlatform {
  final _events = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _events.stream;

  void add(List<ConnectivityResult> results) => _events.add(results);
  Future<void> close() => _events.close();
}
