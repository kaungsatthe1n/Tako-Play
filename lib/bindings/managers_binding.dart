import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../helpers/media_quality_manager.dart';
import '../helpers/network_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../helpers/webview_manager.dart';

/// [ManagerBinding] registers all domain specific controllers used across the
/// whole app. All dependencies are registered using the GetX state management
/// (more about the state management here: https://pub.dev/packages/get ).
class ManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecentWatchManager());
    Get.put(WebViewManager());
    Get.put(MediaQualityManager());
    Get.put(NetworkManager());
    Get.lazyPut(() => BookMarkManager());
  }
}
