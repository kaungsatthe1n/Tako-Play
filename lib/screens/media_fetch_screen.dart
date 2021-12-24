import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tako_play/services/anime_service.dart';
import 'package:tako_play/theme/tako_theme.dart';
import 'package:tako_play/utils/constants.dart';
import 'package:tako_play/utils/routes.dart';

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
    final episodeUrl = Get.arguments['episodeUrl'];
    var videoFile =
        await AnimeService().fetchIframeEmbedded(episodeUrl).catchError((_) {
      Get.dialog(const AlertDialog(
        backgroundColor: tkDarkBlue,
        content: Text('An Error Occurred'),
      ));
      Get.back();
    });
    if (!mounted) return;

    Get.offNamed(Routes.webViewScreen, arguments: {
      'mediaUrl': 'https:' + videoFile.toString(),
    });
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
