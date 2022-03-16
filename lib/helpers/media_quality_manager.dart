import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [MediaQualityManager] uses to set the default video quality of the anime.
class MediaQualityManager extends GetxController {
  /// Default Video Quality is set to 720P if the user hasn't set any quality yet.
  String _defaultQuality = '720 P';
  String get defaultQuality => _defaultQuality;

  void changeMediaQuality(String quality) {
    _defaultQuality = quality;
    _updateVideoQuality(quality);
    update();
  }

  /// Fetches and returns the currently default media quality. Returns `720P` as the default quality
  /// if the user hasn't set any quality yet, or returns the updated quality.
  Future<String> getVideoQuality() async {
    final pref = await SharedPreferences.getInstance();
    final mediaQuality = pref.getString('mediaQuality');
    if (mediaQuality != null) {
      _defaultQuality = mediaQuality;
      update();
    }
    return _defaultQuality;
  }

  /// Updated quality will store in local device
  Future<void> _updateVideoQuality(String quality) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('mediaQuality', quality);
  }
}
