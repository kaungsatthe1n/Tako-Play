import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../helpers/webview_provider.dart';
import '../services/anime_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class MediaFetchScreen extends StatefulWidget {
  const MediaFetchScreen({Key? key}) : super(key: key);

  @override
  State<MediaFetchScreen> createState() => _MediaFetchScreenState();
}

class _MediaFetchScreenState extends State<MediaFetchScreen> {
  final GlobalKey webViewKey = GlobalKey();
  WebViewController? _webViewController;
  final webViewManagerController = Get.find<WebViewManagerController>();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    fetchVideoFile();
  }

  fetchVideoFile() async {
    final animeUrl = Get.arguments['animeUrl'];

    if (webViewManagerController.isWebView) {
      var mediaUrl =
          await AnimeService().fetchIframeEmbedded(animeUrl).catchError((_) {
        Get.dialog(const AlertDialog(
          backgroundColor: tkDarkBlue,
          content: Text('An Error Occurred'),
        ));
        Get.back();
      });
      if (!mounted) return;
      Get.offNamed(Routes.webViewScreen, arguments: {
        'mediaUrl': 'https:' + mediaUrl,
      });
    }
    //else {
    //   var resolutions =
    //       await AnimeService().getVideoWithResolution(animeUrl).catchError((_) {
    //     Get.dialog(const AlertDialog(
    //       backgroundColor: tkDarkBlue,
    //       content: Text('An Error Occurred'),
    //     ));
    //     Get.back();
    //   });
    //   if (!mounted) return;

    //   Get.offNamed(Routes.videoPlayerScreen, arguments: {
    //     'resolutions': resolutions,
    //   });
    // }
  }

  final _random = Random();
  Map<String, String> resolutions = {};
  final animeUrl = Get.arguments['animeUrl'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: webViewManagerController.isWebView
                ? const SizedBox()
                : FutureBuilder<String>(
                    future: AnimeService().fetchIframeEmbedded(animeUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SizedBox.fromSize(
                          size: Size(screenWidth / 1.5, screenHeight / 1.5),
                          child: WebView(
                            initialUrl: 'https:${snapshot.data}',
                            javascriptMode: JavascriptMode.unrestricted,
                            allowsInlineMediaPlayback: true,
                            onWebViewCreated: (controller) async {
                              _webViewController = controller;
                            },
                            onPageFinished: (_) async {
                              // Ads Block
                              for (var i = 0; i < 8; i++) {
                                await _webViewController!
                                    .runJavascriptReturningResult(
                                        "document.getElementsByTagName('iframe')[$i].style.display='none';");
                                await _webViewController!
                                    .runJavascriptReturningResult(
                                        "document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();");
                              }
                              // Fetching VidStreaming Url
                              String rawUrl = await _webViewController!
                                  .runJavascriptReturningResult(
                                      "document.getElementsByClassName('jw-video jw-reset')[0].attributes.src.value;");
                              String url = rawUrl.split("\"").toList()[1];

                              await _webViewController!
                                  .runJavascriptReturningResult(
                                      "if(document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].ariaLabel == 'Play'){document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();}");
                              String resolutionCount = await _webViewController!
                                  .runJavascriptReturningResult(
                                      "document.getElementsByClassName('jw-reset jw-settings-submenu-items')[1].getElementsByClassName('jw-reset-text jw-settings-content-item')['length'];");
                              for (var j = 0;
                                  j < double.parse(resolutionCount) - 1;
                                  j++) {
                                String rawResolution = await _webViewController!
                                    .runJavascriptReturningResult(
                                        "document.getElementsByClassName('jw-reset jw-settings-submenu-items')[1].getElementsByClassName('jw-reset-text jw-settings-content-item')[$j].textContent;");
                                String resolution = rawResolution
                                    .replaceFirst('"', ' ')
                                    .trim()
                                    .replaceFirst('"', ' ')
                                    .trim();
                                String quality = resolution.split(' P')[0];
                                resolutions.putIfAbsent(
                                    resolution,
                                    () => url.replaceFirst(
                                        RegExp(r"(.)[0-9]+(p.mp4)"),
                                        '.${quality}p.mp4'));
                              }

                              Get.offNamed(Routes.videoPlayerScreen,
                                  arguments: {
                                    'url': url,
                                    'resolutions': resolutions,
                                  });
                            },
                            navigationDelegate: (NavigationRequest request) {
                              return NavigationDecision.prevent;
                            },
                            backgroundColor: const Color(0x00000000),
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    }),
          ),
          Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/gif/anime${1 + _random.nextInt(6)}.gif',
                  width: 350,
                  height: 200,
                ),
                SizedBox(
                  height: screenHeight * .10,
                ),
                Text(
                  'Please Wait ...',
                  style: TakoTheme.darkTextTheme.bodyText1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
