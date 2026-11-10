import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/webview_manager.dart';
import '../services/anime_service.dart';
import '../services/playback_service.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/hls_extractor_web_view.dart';
import '../widgets/tako_loading_indicator.dart';

class MediaFetchScreen extends StatefulWidget {
  const MediaFetchScreen({super.key, this.playbackService});

  /// Overrides the playback resolver. Defaults to the configured service.
  final PlaybackService? playbackService;

  @override
  State<MediaFetchScreen> createState() => _MediaFetchScreenState();
}

class _MediaFetchScreenState extends State<MediaFetchScreen> {
  final hasError = false.obs;
  final animeUrl = Get.arguments['animeUrl'];
  List<String> _embeddedMediaUrls = const <String>[];
  var _dynamicExtraction = false;
  var _handoffCompleted = false;

  @override
  void initState() {
    super.initState();
    _openEpisodePlayer();
  }

  Future<void> _openEpisodePlayer() async {
    try {
      // Read the persisted preference here instead of relying on the async
      // startup load, so a selected WebView player always bypasses Better
      // Player and the native HLS resolver.
      final useWebView = await Get.find<WebViewManager>().getVideoPlayerType();
      if (useWebView) {
        _embeddedMediaUrls = await AnimeService(
          requestService: Get.find<RequestService>(),
        ).fetchIframeEmbeds(animeUrl.toString());
        await _openEmbeddedFallback();
        return;
      }

      final playbackService = widget.playbackService ?? PlaybackService();
      if (playbackService.isConfigured) {
        final source =
            await playbackService.resolveEpisode(animeUrl.toString());
        await _openNativePlayer(source);
        return;
      }

      final embeddedMediaUrls = await AnimeService(
        requestService: Get.find<RequestService>(),
      ).fetchIframeEmbeds(animeUrl.toString());
      _embeddedMediaUrls = embeddedMediaUrls;

      // Prefer direct resolution when a page exposes its HLS metadata. Dynamic
      // players are then given a short, offstage extraction pass so their own
      // JavaScript can produce the signed manifest required by the CDN.
      try {
        final source = await playbackService.resolveEmbeddedPlayers(
          embeddedMediaUrls,
          episodeUrl: animeUrl.toString(),
        );
        await _openNativePlayer(source);
        return;
      } on PlaybackResolutionException {
        if (!mounted) return;
        setState(() => _dynamicExtraction = true);
        return;
      }
    } catch (_) {
      hasError.value = true;
    }
  }

  Future<void> _openNativePlayer(PlaybackSource source) async {
    if (!mounted || _handoffCompleted) return;
    _handoffCompleted = true;
    await Get.offNamed(Routes.videoPlayerScreen, arguments: {
      'url': source.url,
      'headers': source.headers,
      'subtitles': source.subtitles,
    });
  }

  Future<void> _openEmbeddedFallback() async {
    if (!mounted || _handoffCompleted) return;
    _handoffCompleted = true;
    await Get.offNamed(Routes.webViewScreen, arguments: {
      'mediaUrls': _embeddedMediaUrls,
      'episodeUrl': animeUrl.toString(),
    });
  }

  Future<void> _retry() async {
    hasError.value = false;
    _handoffCompleted = false;
    setState(() => _dynamicExtraction = false);
    await _openEpisodePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: hasError.value
                        ? const Icon(
                            Icons.error_outline_rounded,
                            key: ValueKey('fetch-error'),
                            color: tkCoral,
                            size: 54,
                          )
                        : const TakoLoadingIndicator(
                            key: ValueKey('fetch-loading'),
                            size: 58,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => Text(
                    hasError.value
                        ? 'Episode can\'t be fetched'
                        : 'Loading video…',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: hasError.value,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: MaterialButton(
                        onPressed: _retry,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: tkGradientBlue,
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_dynamicExtraction && _embeddedMediaUrls.isNotEmpty)
            Offstage(
              child: SizedBox(
                width: 1,
                height: 1,
                child: HlsExtractorWebView(
                  playerUrl: _embeddedMediaUrls.first,
                  referrerUrl: animeUrl.toString(),
                  onSourceFound: _openNativePlayer,
                  onFailure: _openEmbeddedFallback,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
