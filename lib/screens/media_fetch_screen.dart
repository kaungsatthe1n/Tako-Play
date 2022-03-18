import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../helpers/media_quality_manager.dart';
import '../helpers/webview_manager.dart';
import '../services/anime_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/tako_helper.dart';
import '../widgets/tako_play_web_view.dart';

class MediaFetchScreen extends StatefulWidget {
  const MediaFetchScreen({Key? key}) : super(key: key);

  @override
  State<MediaFetchScreen> createState() => _MediaFetchScreenState();
}

class _MediaFetchScreenState extends State<MediaFetchScreen> {
  final GlobalKey webViewKey = GlobalKey();
  final webViewManagerController = Get.find<WebViewManager>();
  final mediaFetchController = Get.find<MediaQualityManager>();
  final _random = Random();
  var hasError = false.obs;
  Map<String, String> resolutions = {};
  List<String> _qualityList = [];
  String _filteredUrl = '';
  final animeUrl = Get.arguments['animeUrl'];
  late final String mediaUrl;

  @override
  void initState() {
    super.initState();
    mediaFetchController.getVideoQuality();
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    fetchVideoFile();
  }

  Future<void> fetchVideoFile() async {
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
      await Get.offNamed(Routes.webViewScreen, arguments: {
        'mediaUrl': 'https:' + mediaUrl,
      });
    }
  }

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
                          size: Size(MediaQuery.of(context).size.width / 1.5,
                              MediaQuery.of(context).size.height / 1.5),
                          child: TakoPlayWebView(
                            initialUrl: 'https:${snapshot.data}',
                            onLoadingFinished: (_webViewController) async {
                              mediaUrl = snapshot.data!;
                              // Ads Block
                              for (var i = 0; i < 8; i++) {
                                await _webViewController
                                    .runJavascriptReturningResult(
                                        "document.getElementsByTagName('iframe')[$i].style.display='none';");
                                await _webViewController
                                    .runJavascriptReturningResult(
                                        "document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();");
                              }
                              // Fetching VidStreaming Url
                              String rawUrl = await _webViewController
                                  .runJavascriptReturningResult(
                                      "document.getElementsByClassName('jw-video jw-reset')[0].attributes.src.value;");
                              for (var i = 0; i < 8; i++) {
                                rawUrl = await _webViewController
                                    .runJavascriptReturningResult(
                                        "document.getElementsByClassName('jw-video jw-reset')[0].attributes.src.value;");
                              }
                              if (rawUrl == 'null' ||
                                  !rawUrl
                                      .contains(RegExp(r'(.)[0-9]+(p.mp4)'))) {
                                hasError.value = true;
                              } else {
                                String url = rawUrl.split('"').toList()[1];
                                // takoDebugPrint(await _webViewController.runJavascriptReturningResult('document.documentElement.outerHTML;'));
                                await _webViewController
                                    .runJavascriptReturningResult(
                                        "if(document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].ariaLabel == 'Play'){document.getElementsByClassName('jw-icon jw-icon-display jw-button-color jw-reset')[0].click();}");
                                String resolutionCount = await _webViewController
                                    .runJavascriptReturningResult(
                                        "document.getElementsByClassName('jw-reset jw-settings-submenu-items')[1].getElementsByClassName('jw-reset-text jw-settings-content-item')['length'];");
                                for (var j = 0;
                                    j < double.parse(resolutionCount) - 1;
                                    j++) {
                                  String rawResolution = await _webViewController
                                      .runJavascriptReturningResult(
                                          "document.getElementsByClassName('jw-reset jw-settings-submenu-items')[1].getElementsByClassName('jw-reset-text jw-settings-content-item')[$j].textContent;");
                                  String resolution = rawResolution
                                      .replaceFirst('"', ' ')
                                      .trim()
                                      .replaceFirst('"', ' ')
                                      .trim();
                                  String quality = resolution.split(' P')[0];
                                  _qualityList.add(quality);
                                  resolutions.putIfAbsent(
                                      resolution,
                                      () => url.replaceFirst(
                                          RegExp(r'(.)[0-9]+(p.mp4)'),
                                          '.${quality}p.mp4'));
                                }
                                for (var qlt in _qualityList) {
                                  if (mediaFetchController.defaultQuality
                                      .contains(qlt)) {
                                    _filteredUrl = url.replaceAll(
                                        RegExp(r'(.)[0-9]+(p.mp4)'),
                                        '.${qlt}p.mp4');
                                  }
                                }
                                // takoDebugPrint('Filter Url : $_filteredUrl');
                                if (_filteredUrl != '') {
                                  await Get.offNamed(Routes.videoPlayerScreen,
                                      arguments: {
                                        'url': _filteredUrl,
                                        'resolutions': resolutions,
                                      });
                                } else {
                                  await Get.offNamed(Routes.videoPlayerScreen,
                                      arguments: {
                                        'url': url,
                                        'resolutions': resolutions,
                                      });
                                }
                              }
                            },
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
                Obx(
                  () => Image.asset(
                    hasError.value
                        ? 'assets/gif/anime-cry.gif'
                        : 'assets/gif/anime${1 + _random.nextInt(25)}.gif',
                    width: 350,
                    height: 200,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Obx(
                  () => Visibility(
                    visible: !hasError.value,
                    child: Text(
                      'Please Wait ...',
                      style: TakoTheme.darkTextTheme.bodyText1,
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: hasError.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Episode can\'t be fetch',
                        style: TakoTheme.darkTextTheme.headline3,
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: hasError.value,
                    child: MaterialButton(
                      onPressed: hasError.value
                          ? () {
                              Get.offNamed(Routes.webViewScreen, arguments: {
                                'mediaUrl': 'https:' + mediaUrl,
                              });
                            }
                          : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: tkGradientBlue,
                      child: Text(
                        'Continue with WebView Player',
                        style: TakoTheme.darkTextTheme.headline3!
                            .copyWith(fontSize: 17.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
