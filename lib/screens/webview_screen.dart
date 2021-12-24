import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  var isLandScape = true.obs;

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
    return WillPopScope(
      onWillPop: () async {
        if (!isLandScape.value) {
          return true;
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          SystemChrome.setPreferredOrientations([
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
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0x00000000),
                ),
                WebView(
                  initialUrl: Get.arguments['mediaUrl'],
                  javascriptMode: JavascriptMode.unrestricted,
                  navigationDelegate: (NavigationRequest request) {
                    return NavigationDecision.prevent;
                  },
                  backgroundColor: const Color(0x00000000),
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
