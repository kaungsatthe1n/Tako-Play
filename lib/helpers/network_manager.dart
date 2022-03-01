import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:get/get.dart';

/// [NetworkManager] is used for handling online connectivity state of the app.
/// It provides an easy way of checking whether the device is online or not
class NetworkManager extends GetxController {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = false;

  /// State indicating online connection
  bool get isOnline => _isOnline;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  /// Manually checks whether the app is connected to internet
  Future<void> checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _onNetworkStateUpdated(connectivityResult);
  }

  /// Starts monitoring the actual network connection
  Future<void> _startMonitoring() async {
    _connectivity.onConnectivityChanged.listen(_onNetworkStateUpdated);

    // Make the initial connectivity check (just to be sure)
    await checkConnection();
  }

  /// Callback triggered once there is a change in network connection
  void _onNetworkStateUpdated(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _isOnline = false;

      update();
    } else {
      _isOnline = true;

      update();
    }
  }
}
