import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebViewManagerController extends GetxController {
  bool webView = false;
  bool get isWebView => webView;

  void changeWebViewType(value) {
    webView = value;
    updateVideoPlayerType(value);
    update();
  }

  Future<void> getVideoPlayerType() async {
    final pref = await SharedPreferences.getInstance();
    final isWebView = pref.getBool('isWebViewPlayerType');
    if (isWebView != null) {
      webView = isWebView;
      update();
    } else {
      webView = false;
      update();
    }
  }

  Future<void> updateVideoPlayerType(flag) async {
    final pref = await SharedPreferences.getInstance();
    pref.setBool('isWebViewPlayerType', flag);
  }
}
