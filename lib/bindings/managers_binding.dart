import 'package:get/get.dart';
import '../helpers/bookmark_manager.dart';
import '../helpers/network_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../helpers/webview_manager.dart';

class ManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecentWatchManager());
    Get.lazyPut(() => WebViewManager());
    Get.put(NetworkManager());
    Get.lazyPut(() => BookMarkManager());
  }
}
