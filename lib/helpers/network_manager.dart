import 'dart:async';
import 'package:connectivity/connectivity.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = false;

  bool get isOnline => _isOnline;

  @override
  void onInit() {
    super.onInit();
    startMornitoring();
  }

  Future<void> startMornitoring() async {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        _isOnline = false;

        update();
      } else {
        _isOnline = true;

        update();
      }
    });
  }

  // Future<void> initConnectivity() async {
  //   try {
  //     var status = await _connectivity.checkConnectivity();

  //     if (status == ConnectivityResult.none) {
  //       _isOnline = false;
  //       update();
  //     } else {
  //       _isOnline = true;
  //       update();
  //     }
  //   } on PlatformException catch (e) {
  //     // ignore: avoid_print
  //     print(e.toString());
  //   }
  // }
}
