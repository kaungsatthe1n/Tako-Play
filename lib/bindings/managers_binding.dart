import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../helpers/media_quality_manager.dart';
import '../helpers/network_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../helpers/update_manager.dart';
import '../helpers/webview_manager.dart';
import '../services/request_service.dart';

/// [ManagerBinding] registers all domain specific controllers used across the
/// whole app. All dependencies are registered using the GetX state management
/// (more about the state management here: https://pub.dev/packages/get ).
class ManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RequestService.create(), permanent: true);
    Get.put(RecentWatchManager(), permanent: true);
    Get.put(WebViewManager(), permanent: true);
    Get.put(MediaQualityManager(), permanent: true);
    Get.put(NetworkManager(), permanent: true);
    Get.put(BookMarkManager(), permanent: true);
    Get.put(UpdateManager(), permanent: true);
  }
}
