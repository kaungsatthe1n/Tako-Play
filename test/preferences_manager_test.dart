import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/helpers/media_quality_manager.dart';
import 'package:tako_play/helpers/webview_manager.dart';

void main() {
  test('media quality loads and persists the selected value', () async {
    SharedPreferences.setMockInitialValues({'mediaQuality': '480 P'});
    final manager = MediaQualityManager();

    await manager.getVideoQuality();
    expect(manager.defaultQuality, '480 P');

    await manager.changeMediaQuality('1080 P');
    expect(manager.defaultQuality, '1080 P');
    expect((await SharedPreferences.getInstance()).getString('mediaQuality'),
        '1080 P');
  });

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
}
