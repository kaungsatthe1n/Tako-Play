import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/constants.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  var isLandScape = true.obs;
  final GlobalKey webViewKey = GlobalKey();
  WebViewController? _webViewController;

  /// The initial url to start with
  late final String _initialUrl;

  @override
  void initState() {
    super.initState();
    _initialUrl = Get.arguments['mediaUrl'].toString();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    if (Platform.isIOS) WebView.platform = CupertinoWebView();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
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
    return WillPopScope(
      onWillPop: () async {
        if (!isLandScape.value) {
          return true;
        } else {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
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
            isLandScape.value = true;
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.immersiveSticky,
            );
          } else {
            isLandScape.value = false;
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [
                SystemUiOverlay.top,
                SystemUiOverlay.bottom,
              ],
            );
          }
          return AspectRatio(
            aspectRatio:
                orientation == Orientation.landscape ? 16 / 9 : 4 / 2.885,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SizedBox.fromSize(
                  size: Size(screenWidth, screenHeight),
                  child: WebView(
                    initialUrl: Get.arguments['mediaUrl'].toString(),
                    javascriptMode: JavascriptMode.unrestricted,
                    allowsInlineMediaPlayback: true,
                    onWebViewCreated: (controller) async {
                      _webViewController = controller;
                    },
                    onPageFinished: (_) async {
                      await Future.delayed(const Duration(seconds: 1));

                      try {
                        //
                        for (var i = 0; i < 8; i++) {
                          await _webViewController!.runJavascriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                          await _webViewController!.runJavascriptReturningResult(
                              "document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();");
                        }
                        //
                        for (var i = 0; i < 8; i++) {
                          await _webViewController!.runJavascriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                        }
                        await _webViewController!.runJavascriptReturningResult(
                            "document.getElementsByClassName('jw-icon jw-icon-inline jw-button-color jw-reset jw-icon-fullscreen')[1].click();");
                        await _webViewController!.runJavascriptReturningResult(
                            "if(document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].ariaLabel == 'Play'){document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();}");
                        //
                        for (var i = 0; i < 8; i++) {
                          await _webViewController!.runJavascriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                        }
                      } catch (e) {
                        print(
                            'An error occurred while parsing data from webview:');
                        print(e.toString());
                        rethrow;
                      }
                    },
                    navigationDelegate: (NavigationRequest request) {
                      // If we are navigating to the destination url, allow it.
                      if (request.url == _initialUrl) {
                        return NavigationDecision.navigate;
                      }

                      // Otherwise, reject any navigation to other web urls
                      return NavigationDecision.prevent;
                    },
                    backgroundColor: const Color(0x00000000),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 10,
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (isLandScape.value) {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                              ]);
                            } else {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.landscapeRight,
                                DeviceOrientation.landscapeLeft,
                              ]);
                            }
                          },
                          icon: const Icon(
                            Icons.zoom_out_map_outlined,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        })),
      ),
    );
  }
}
