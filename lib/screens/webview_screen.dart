import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    super.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    return WillPopScope(
      onWillPop: () async {
        if (MediaQuery.of(context).orientation == Orientation.portrait) {
          return true;
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);

          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: OrientationBuilder(builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.immersiveSticky,
            );
          } else {
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [
                SystemUiOverlay.top,
                SystemUiOverlay.bottom,
              ],
            );
          }
          return AspectRatio(
            aspectRatio: orientation == Orientation.landscape ? 16 / 9 : 1,
            child: WebView(
              initialUrl: routes['mediaUrl'],
              javascriptMode: JavascriptMode.unrestricted,
              initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
              },
              onProgress: (int progress) {
                print('WebView is loading (progress : $progress%)');
              },
              onPageFinished: (_) {
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.immersiveSticky,
                );
              },
              navigationDelegate: (NavigationRequest request) {
                return NavigationDecision.prevent;
              },
              backgroundColor: const Color(0x00000000),
            ),
          );
        })),
      ),
    );
  }
}
