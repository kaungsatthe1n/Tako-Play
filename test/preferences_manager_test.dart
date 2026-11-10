import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/helpers/webview_manager.dart';

void main() {
  test('web view preference loads and persists', () async {
    SharedPreferences.setMockInitialValues({'isWebViewPlayerType': true});
    final manager = WebViewManager();

    await manager.getVideoPlayerType();
    expect(manager.isWebView, isTrue);

    await manager.changeWebViewType(false);
    expect(manager.isWebView, isFalse);
    expect(
        (await SharedPreferences.getInstance()).getBool('isWebViewPlayerType'),
        isFalse);
  });

  test('uses BetterPlayer by default when no player preference is saved',
      () async {
    SharedPreferences.setMockInitialValues({});
    final manager = WebViewManager();

    await manager.getVideoPlayerType();

    expect(manager.isWebView, isFalse);
  });
}
