import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/constants.dart';
import '../widgets/tako_loading_indicator.dart';

/// Native HLS player using the official, maintained Better Player package.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final BetterPlayerController _controller;

  @override
  void initState() {
    super.initState();
    final streamHeaders = Map<String, String>.from(
      Get.arguments['headers'] as Map? ?? const <String, String>{},
    );
    _controller = BetterPlayerController(
      PlayerConfiguration(
        autoDetectFullscreenAspectRatio: true,
        autoDetectFullscreenDeviceOrientation: true,
        aspectRatio: 16 / 9,
        autoPlay: true,
        allowedScreenSleep: false,
        autoDispose: true,
        fullScreenByDefault: true,
        fullScreenAspectRatio: 16 / 9,
        controlsConfiguration: const PlayerControlsConfiguration(
          controlBarColor: tkDarkBlue,
          loadingWidget: TakoLoadingIndicator(size: 34),
          overflowMenuIconsColor: Colors.white,
          overflowModalColor: Colors.black87,
          overflowModalTextColor: Colors.white,
          pauseIcon: Icons.pause_outlined,
          playIcon: Icons.play_arrow,
          playerTheme: PlayerTheme.cupertino,
          progressBarBackgroundColor: tkGrey,
          progressBarBufferedColor: Colors.grey,
          progressBarHandleColor: Colors.white,
          progressBarPlayedColor: tkGradientBlue,
        ),
      ),
      betterPlayerDataSource: PlayerDataSource(
        DataSourceType.network,
        Get.arguments['url'].toString(),
        bufferingConfiguration: const BufferingConfiguration(
          minBufferMs: 60000,
          maxBufferMs: 555000,
        ),
        cacheConfiguration: const CacheConfiguration(
          useCache: true,
          preCacheSize: 400000,
          maxCacheSize: 400000,
          maxCacheFileSize: 400000,
        ),
        // Signed CDN headers come from the first-party playback resolver. The
        // legacy source headers remain as a fallback for existing callers.
        headers: streamHeaders.isEmpty ? header : streamHeaders,
        resolutions: Map<String, String>.from(
          Get.arguments['resolutions'] as Map? ?? const <String, String>{},
        ),
        videoFormat: VideoFormat.hls,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BetterPlayer(controller: _controller),
    );
  }
}
