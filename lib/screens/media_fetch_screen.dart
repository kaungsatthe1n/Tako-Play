import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  @override
  void initState() {
    super.initState();
    fetchVideoFile();
  }

  fetchVideoFile() async {
    final animeUrl = Get.arguments['animeUrl'];

    final webViewController = Get.find<WebViewController>();

    if (webViewController.isWebView) {
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
    } else {
      var resolutions =
          await AnimeService().getVideoWithResolution(animeUrl).catchError((_) {
        Get.dialog(const AlertDialog(
          backgroundColor: tkDarkBlue,
          content: Text('An Error Occurred'),
        ));
        Get.back();
      });
      if (!mounted) return;

      Get.offNamed(Routes.videoPlayerScreen, arguments: {
        'resolutions': resolutions,
      });
    }
  }

  final _random = Random();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
    );
  }
}
