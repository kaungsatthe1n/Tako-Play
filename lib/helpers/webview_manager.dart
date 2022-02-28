import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [WebViewManager] manages the state of the web-view video player, allowing
/// to turn it on/off at any time.
class WebViewManager extends GetxController {
  /// Flag indicating whether we are using a web-view based video player
  bool _webView = false;

  bool get isWebView => _webView;

  /// Updates the state of the video player from/to web-view
  void changeWebViewType(value) {
    _webView = value;
    _updateVideoPlayerType(value);
    update();
  }

  /// Fetches and returns the currently active video player type. Returns `true`
  /// if web view player is enabled, or `false` if not.
  Future<bool> getVideoPlayerType() async {
    final pref = await SharedPreferences.getInstance();
    final isWebView = pref.getBool('isWebViewPlayerType');
    if (isWebView != null) {
      _webView = isWebView;
      update();
    } else {
      _webView = false;
      update();
    }
    return _webView;
  }

  /// Updates local settings for the web view player usage
  Future<void> _updateVideoPlayerType(flag) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('isWebViewPlayerType', flag);
  }
}
