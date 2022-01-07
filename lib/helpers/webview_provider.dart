// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class WebViewController extends GetxController {
//   bool webView = true;
//   bool get isWebView => webView;

//   void changeWebViewType(value) {
//     webView = value;
//     updateVideoPlayerType(value);
//     update();
//   }

//   Future<void> getVideoPlayerType() async {
//     final pref = await SharedPreferences.getInstance();
//     final isWebView = pref.getBool('isWebViewPlayer');
//     if (isWebView != null) {
//       webView = isWebView;
//       update();
//     } else {
//       webView = true;
//       update();
//     }
//   }

//   Future<void> updateVideoPlayerType(flag) async {
//     final pref = await SharedPreferences.getInstance();
//     pref.setBool('isWebViewPlayer', flag);
//   }
// }
