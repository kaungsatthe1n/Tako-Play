import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../utils/tako_helper.dart';
import '../widgets/tako_play_web_view.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  var isLandScape = true.obs;
  final GlobalKey webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    takoDebugPrint(Get.arguments['mediaUrl'].toString());
    print(Get.arguments['mediaUrl'].toString());
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
                  size: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  child: TakoPlayWebView(
                    initialUrl: Get.arguments['mediaUrl'].toString(),
                    onLoadingFinished: (webViewController) async {
                      try {
                        //
                        for (var i = 0; i < 10; i++) {
                          await webViewController.runJavaScriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                          await webViewController.runJavaScriptReturningResult(
                              "document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();");
                        }
                        //
                        for (var i = 0; i < 8; i++) {
                          await webViewController.runJavaScriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                        }
                        await webViewController.runJavaScriptReturningResult(
                            "document.getElementsByClassName('jw-icon jw-icon-inline jw-button-color jw-reset jw-icon-fullscreen')[1].click();");
                        await webViewController.runJavaScriptReturningResult(
                            "if(document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].ariaLabel == 'Play'){document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();}");
                        //
                        for (var i = 0; i < 8; i++) {
                          await webViewController.runJavaScriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                        }
                        await Future.delayed(const Duration(seconds: 1));
                        for (var i = 0; i < 10; i++) {
                          await webViewController.runJavaScriptReturningResult(
                              "document.getElementsByTagName('iframe')[$i].style.display='none';");
                        }
                      } catch (e) {
                        print(
                            'An error occurred while parsing data from webView:');
                        print(e.toString());
                        rethrow;
                      }
                    },
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
