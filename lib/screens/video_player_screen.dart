import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/anime_service.dart';
import '../utils/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key? key}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late BetterPlayerController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    fetchVideoFile();
  }

  fetchVideoFile() async {
    var videoFile = await AnimeService()
        .getVideoUrl(Get.arguments['episodeUrl'])
        .catchError((_) {
      Get.dialog(const AlertDialog(
        backgroundColor: tkDarkBlue,
        content: Text('No Internet Connection'),
      ));
      Get.back();
    });

    setState(() {
      isLoading = false;
    });
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        fullScreenByDefault: true,
        autoDetectFullscreenAspectRatio: true,
        aspectRatio: 16 / 10,
        handleLifecycle: false,
        autoDetectFullscreenDeviceOrientation: true,
        autoPlay: true,
        allowedScreenSleep: false,
        autoDispose: true,
        fullScreenAspectRatio: 16 / 10,
        controlsConfiguration: BetterPlayerControlsConfiguration(),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network, videoFile.toString(),
          headers: header),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        return !isLoading;
      },
      child: Scaffold(
          key: _formKey,
          backgroundColor: Colors.black,
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : BetterPlayer(
                  controller: _controller,
                )),
    );
  }
}
