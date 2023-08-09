import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

import '../utils/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key? key}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late BetterPlayerController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    WidgetsBinding.instance.addObserver(this);

    mediaPlayerControllerSetUp();
    _controller.setOverriddenFit(BoxFit.contain);
  }

  final indicator = const SpinKitSquareCircle(
    color: Colors.white,
    size: 28,
  );

  void mediaPlayerControllerSetUp() {
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoDetectFullscreenAspectRatio: true,
        fit: BoxFit.fitHeight,
        aspectRatio: 16 / 9,
        handleLifecycle: false,
        autoDetectFullscreenDeviceOrientation: true,
        autoPlay: true,
        allowedScreenSleep: false,
        autoDispose: true,
        fullScreenByDefault: true,
        fullScreenAspectRatio: 16 / 9,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          overflowModalColor: Colors.black87,
          overflowMenuIconsColor: Colors.white,
          overflowModalTextColor: Colors.white,
          playIcon: Icons.play_arrow,
          pauseIcon: Icons.pause_outlined,
          playerTheme: BetterPlayerTheme.cupertino,
          controlBarColor: tkDarkBlue.withOpacity(.75),
          loadingWidget: indicator,
          progressBarPlayedColor: tkGradientBlue,
          progressBarBufferedColor: Colors.grey,
          progressBarBackgroundColor: tkGrey,
          progressBarHandleColor: Colors.white,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Get.arguments['url'].toString(),
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 60000,
          maxBufferMs: 555000,
        ),
        resolutions: Get.arguments['resolutions'],
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          preCacheSize: 400000,
          maxCacheSize: 400000,
          maxCacheFileSize: 400000,
        ),
        headers: header,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.setControlsAlwaysVisible(true);
        break;
      case AppLifecycleState.inactive:
        _controller.pause();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller.clearCache();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        if (!isPortrait) {
          _controller.exitFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
          key: _formKey,
          backgroundColor: Colors.black,
          body: BetterPlayer(
            controller: _controller,
          )),
    );
  }
}
