import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/anime_service.dart';
import '../services/playback_service.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/tako_loading_indicator.dart';

class MediaFetchScreen extends StatefulWidget {
  const MediaFetchScreen({super.key});

  @override
  State<MediaFetchScreen> createState() => _MediaFetchScreenState();
}

class _MediaFetchScreenState extends State<MediaFetchScreen> {
  final hasError = false.obs;
  final animeUrl = Get.arguments['animeUrl'];

  @override
  void initState() {
    super.initState();
    _openEpisodePlayer();
  }

  Future<void> _openEpisodePlayer() async {
    try {
      final playbackService = PlaybackService();
      if (playbackService.isConfigured) {
        final source =
            await playbackService.resolveEpisode(animeUrl.toString());
        if (!mounted) return;
        await Get.offNamed(Routes.videoPlayerScreen, arguments: {
          'url': source.url,
          'headers': source.headers,
        });
        return;
      }

      final embeddedMediaUrls = await AnimeService(
        requestService: Get.find<RequestService>(),
      ).fetchIframeEmbeds(animeUrl.toString());
      if (!mounted) return;
      await Get.offNamed(Routes.webViewScreen, arguments: {
        'mediaUrls': embeddedMediaUrls,
        'episodeUrl': animeUrl.toString(),
      });
    } catch (_) {
      hasError.value = true;
    }
  }

  Future<void> _retry() async {
    hasError.value = false;
    await _openEpisodePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                hasError.value ? 'Episode can\'t be fetched' : 'Loading video…',
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
    );
  }
}
