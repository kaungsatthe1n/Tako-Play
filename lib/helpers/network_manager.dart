import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// [NetworkManager] is used for handling online connectivity state of the app.
/// It provides an easy way of checking whether the device is online or not
class NetworkManager extends GetxController {
  NetworkManager({
    Connectivity? connectivity,
    http.Client? client,
    Uri? sourceUri,
    bool autoStart = true,
  })  : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client(),
        _ownsClient = client == null,
        _sourceUri = sourceUri ?? Uri.parse(sourceBaseUrl),
        _autoStart = autoStart;

  final Connectivity _connectivity;
  final http.Client _client;
  final bool _ownsClient;
  final Uri _sourceUri;
  final bool _autoStart;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;

  /// State indicating online connection
  bool get isOnline => _isOnline;

  @override
  void onInit() {
    super.onInit();
    if (_autoStart) _startMonitoring();
  }

  /// Manually checks whether the app is connected to internet
  Future<void> checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    await updateConnectionState(connectivityResult);
  }

  /// Starts monitoring the actual network connection
  Future<void> _startMonitoring() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(updateConnectionState);

    // Make the initial connectivity check (just to be sure)
    await checkConnection();
  }

  /// Callback triggered once there is a change in network connection
  Future<void> updateConnectionState(List<ConnectivityResult> results) async {
    final hasNetworkInterface =
        results.any((result) => result != ConnectivityResult.none);
    _isOnline = hasNetworkInterface && await _canReachSource();
    update();
  }

  Future<bool> _canReachSource() async {
    try {
      final response =
          await _client.head(_sourceUri).timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    if (_ownsClient) _client.close();
    super.onClose();
  }
}
