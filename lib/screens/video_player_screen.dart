import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../helpers/next_episode_controller.dart';
import '../helpers/recent_watch_manager.dart';
import '../models/playback_context.dart';
import '../models/recent_anime.dart';
import '../services/anime_service.dart';
import '../services/ending_timing_service.dart';
import '../services/playback_service.dart';
import '../services/request_service.dart';
import '../services/subtitle_prefetch_service.dart';
import '../utils/constants.dart';
import '../widgets/hls_extractor_web_view.dart';
import '../widgets/next_episode_overlay.dart';
import '../widgets/tako_loading_indicator.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, this.nextSourceLoader});

  /// Allows deterministic playback integration tests without external sources.
  final Future<PlaybackSource> Function(PlaybackContext)? nextSourceLoader;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final BetterPlayerController _controller;
  late final NextEpisodeController _nextEpisode;
  final _endingService = EndingTimingService();
  final _subtitleService = SubtitlePrefetchService();
  _ExtractionRequest? _extraction;
  int _extractionGeneration = 0;
  final List<PlayerEvent> _playerEventsBeforeReady = <PlayerEvent>[];
  bool _controllerReady = false;
  bool _closing = false;
  bool _isSkippingOpening = false;
  bool _isApplyingResumeSeek = false;
  bool _resumeRestoreStarted = false;
  bool _resumeRestoreFinished = false;
  Duration? _initialResumePosition;
  RecentAnime? _recentAnime;
  String? _lastSavedProgressKey;
  int _lastSavedProgressMillis = -1;

  @override
  void initState() {
    super.initState();
    // The app is portrait-locked outside playback. Unlock orientations before
    // BetterPlayer's first initialized event requests landscape on iOS.
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    final args = Map<String, dynamic>.from(Get.arguments as Map);
    _recentAnime = args['recentAnime'] as RecentAnime?;
    final resumePosition = args['resumePosition'];
    if (resumePosition is Duration && resumePosition > Duration.zero) {
      _initialResumePosition = resumePosition;
    }
    _nextEpisode = NextEpisodeController(
      context: args['playbackContext'] as PlaybackContext?,
      endingStart: args['endingStart'] as Duration?,
      opening: args['opening'] as SkipInterval?,
      loadSource: widget.nextSourceLoader ?? _prefetchNext,
      findEnding: _endingService.fetchEnding,
      playSource: _playNext,
      skipOpening: _seekPastOpening,
    );
    final initialSource = PlaybackSource(
      url: args['url'].toString(),
      headers: Map<String, String>.from(args['headers'] as Map? ?? const {}),
      subtitles: (args['subtitles'] as List? ?? const [])
          .whereType<PlaybackSubtitle>()
          .toList(growable: false),
      endingStart: args['endingStart'] as Duration?,
      opening: args['opening'] as SkipInterval?,
    );
    _controller = BetterPlayerController(
      PlayerConfiguration(
        autoDetectFullscreenAspectRatio: true,
        autoDetectFullscreenDeviceOrientation: true,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        allowedScreenSleep: false,
        autoDispose: false,
        fullScreenByDefault: true,
        fullScreenAspectRatio: 16 / 9,
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        eventListener: _onPlayerEvent,
        // The built-in overlay is below the controls' gesture layer. Wrap the
        // fullscreen route so these buttons remain above it and tappable.
        routePageBuilder: (context, animation, secondaryAnimation, player) =>
            _playerSurface(player),
        controlsConfiguration: const PlayerControlsConfiguration(
          controlBarColor: tkDarkBlue,
          enablePip: false,
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
      betterPlayerDataSource: _dataSource(initialSource,
          resolutions: Map<String, String>.from(
              args['resolutions'] as Map? ?? const {})),
    );
    // BetterPlayer can emit its first progress event synchronously from its
    // constructor while it starts the initial data source. Defer those events
    // until the late-final controller assignment above has completed.
    _controllerReady = true;
    if (_playerEventsBeforeReady.isNotEmpty) {
      final pendingEvents = List<PlayerEvent>.of(_playerEventsBeforeReady);
      _playerEventsBeforeReady.clear();
      for (final event in pendingEvents) {
        _handlePlayerEvent(event);
      }
    }
    if (_nextEpisode.context == null && args['recentAnime'] is RecentAnime) {
      unawaited(_restoreEpisodeContext(args['recentAnime'] as RecentAnime));
    }
  }

  Future<void> _restoreEpisodeContext(RecentAnime recent) async {
    // Existing fragment-based rows already contain the detail URL. Do not
    // invent title URLs for old sources that use separate episode pages.
    final uri = Uri.tryParse(recent.epUrl);
    final detailUrl = recent.animeUrl.isNotEmpty
        ? recent.animeUrl
        : (uri?.fragment.startsWith('episode=') == true
            ? uri!.removeFragment().toString()
            : '');
    if (detailUrl.isEmpty) return;
    try {
      final anime =
          await AnimeService(requestService: Get.find<RequestService>())
              .fetchAnimeDetails(detailUrl);
      var index =
          anime.episodes.indexWhere((episode) => episode.link == recent.epUrl);
      if (index < 0) {
        // Older recent rows can carry an episode URL that was rewritten by a
        // provider. Its saved episode label is still a stable exact match.
        final episodeLabel = recent.currentEp
            .trim()
            .replaceFirst(
                RegExp(r'^(?:episode|ep)\s*', caseSensitive: false), '')
            .trim();
        if (episodeLabel.isNotEmpty) {
          index = anime.episodes.indexWhere((episode) =>
              episode.number.trim().toLowerCase() ==
              episodeLabel.toLowerCase());
        }
      }
      if (_closing || !mounted || index < 0) return;
      _nextEpisode.attachContext(PlaybackContext(
          id: recent.id,
          name: recent.name,
          imageUrl: recent.imageUrl,
          animeUrl: detailUrl,
          episodes: anime.episodes,
          index: index));
    } catch (_) {
      /* Playback continues even if the episode list is unavailable. */
    }
  }

  PlayerDataSource _dataSource(PlaybackSource source,
          {Map<String, String> resolutions = const {}}) =>
      PlayerDataSource(
        DataSourceType.network,
        source.url,
        bufferingConfiguration: const BufferingConfiguration(
            minBufferMs: 60000, maxBufferMs: 555000),
        cacheConfiguration: const CacheConfiguration(
            useCache: true,
            preCacheSize: 400000,
            maxCacheSize: 400000,
            maxCacheFileSize: 400000),
        headers: source.headers.isEmpty ? header : source.headers,
        subtitles: source.subtitles
            .map((subtitle) => PlayerSubtitlesSource(
                  type: subtitle.content == null
                      ? PlayerSubtitlesSourceType.network
                      : PlayerSubtitlesSourceType.memory,
                  content: subtitle.content,
                  name: subtitle.name,
                  urls: [subtitle.url],
                  headers: subtitle.headers.isEmpty ? null : subtitle.headers,
                  selectedByDefault: subtitle.selectedByDefault,
                ))
            .toList(growable: false),
        resolutions: resolutions,
        videoFormat: VideoFormat.hls,
      );

  void _onPlayerEvent(PlayerEvent event) {
    if (_closing) return;
    if (!_controllerReady) {
      _playerEventsBeforeReady.add(event);
      return;
    }
    _handlePlayerEvent(event);
  }

  void _handlePlayerEvent(PlayerEvent event) {
    if (_closing) return;
    if (event.betterPlayerEventType == PlayerEventType.initialized) {
      unawaited(_restoreInitialPosition());
      return;
    }
    if (event.betterPlayerEventType == PlayerEventType.seekTo) {
      if (_isSkippingOpening || _isApplyingResumeSeek) return;
      _nextEpisode.onSeek();
      _cancelNextExtraction();
      return;
    }
    if (event.betterPlayerEventType == PlayerEventType.pause ||
        event.betterPlayerEventType == PlayerEventType.hideFullscreen) {
      final value = _controller.videoPlayerValue;
      final duration = value?.duration;
      if (_resumeRestoreFinished &&
          value != null &&
          duration != null &&
          duration > Duration.zero) {
        unawaited(_persistEpisodeProgress(
          value.position,
          duration,
          completed: false,
          force: true,
        ));
      }
    }
    if (event.betterPlayerEventType == PlayerEventType.progress ||
        event.betterPlayerEventType == PlayerEventType.finished) {
      final playerValue = _controller.videoPlayerValue;
      final position = event.parameters?['progress'] ??
          (event.betterPlayerEventType == PlayerEventType.finished
              ? playerValue?.duration
              : null);
      final duration = event.parameters?['duration'] ?? playerValue?.duration;
      if (position is Duration && duration is Duration) {
        _nextEpisode.updateProgress(position, duration);
        if (_resumeRestoreFinished) {
          unawaited(_persistEpisodeProgress(
            position,
            duration,
            completed: event.betterPlayerEventType == PlayerEventType.finished,
          ));
        }
      }
    }
  }

  Future<void> _restoreInitialPosition() async {
    if (_resumeRestoreStarted || _closing) return;
    _resumeRestoreStarted = true;
    final resumePosition = _initialResumePosition;
    try {
      final duration = _controller.videoPlayerValue?.duration;
      if (resumePosition != null &&
          resumePosition > const Duration(seconds: 3) &&
          duration != null &&
          duration > resumePosition) {
        _isApplyingResumeSeek = true;
        await _controller.seekTo(resumePosition);
      }
    } catch (_) {
      // Playback should continue from the start if restoring the seek fails.
    } finally {
      _isApplyingResumeSeek = false;
      _resumeRestoreFinished = true;
    }
  }

  Future<void> _persistEpisodeProgress(
    Duration position,
    Duration duration, {
    required bool completed,
    bool force = false,
  }) async {
    if (!Get.isRegistered<RecentWatchManager>() || duration <= Duration.zero) {
      return;
    }
    final context = _nextEpisode.context;
    final recent = _recentAnime;
    final animeId = context?.id ?? recent?.id;
    final episodeUrl = context?.episode.link ?? recent?.epUrl;
    final episodeNumber = context?.episode.number ??
        recent?.currentEp.replaceFirst(
          RegExp(r'^(?:episode|ep)\s*', caseSensitive: false),
          '',
        ) ??
        '';
    if (animeId == null || episodeUrl == null || episodeUrl.isEmpty) return;

    final progressKey = '$animeId\u0000$episodeUrl';
    final savedPosition = completed ? duration : position;
    final savedMillis = savedPosition.inMilliseconds;
    if (!completed &&
        !force &&
        progressKey == _lastSavedProgressKey &&
        _lastSavedProgressMillis >= 0 &&
        (savedMillis - _lastSavedProgressMillis).abs() < 5000) {
      return;
    }
    _lastSavedProgressKey = progressKey;
    _lastSavedProgressMillis = savedMillis;
    try {
      await Get.find<RecentWatchManager>().saveProgress(
        animeId: animeId,
        episodeUrl: episodeUrl,
        episodeNumber: episodeNumber,
        positionMillis: savedMillis,
        durationMillis: duration.inMilliseconds,
      );
    } catch (_) {
      // Progress persistence must not interrupt playback.
    }
  }

  Future<void> _seekPastOpening(Duration end) async {
    _isSkippingOpening = true;
    try {
      await _controller.seekTo(end);
    } finally {
      _isSkippingOpening = false;
    }
  }

  Future<PlaybackSource> _prefetchNext(PlaybackContext context) async {
    final resolver = PlaybackService();
    PlaybackSource source;
    if (resolver.isConfigured) {
      source = await resolver.resolveEpisode(context.episode.link);
    } else {
      final embeds =
          await AnimeService(requestService: Get.find<RequestService>())
              .fetchIframeEmbeds(context.episode.link);
      try {
        source = await resolver.resolveEmbeddedPlayers(embeds,
            episodeUrl: context.episode.link);
      } on PlaybackResolutionException {
        if (_closing || !mounted || embeds.isEmpty) rethrow;
        source = await _extractNext(embeds, context.episode.link);
      }
    }
    if (_closing) throw StateError('Player closed');
    return _subtitleService.prepare(source);
  }

  Future<PlaybackSource> _extractNext(
      List<String> urls, String episodeUrl) async {
    final generation = _extractionGeneration;
    for (final url in urls) {
      if (_closing || !mounted || generation != _extractionGeneration) break;
      final request = _ExtractionRequest(url, episodeUrl);
      setState(() => _extraction = request);
      final source = await request.result.future;
      if (!_closing && mounted) setState(() => _extraction = null);
      if (generation != _extractionGeneration) {
        throw const PlaybackResolutionException(
            'Prefetch stopped because playback was sought.');
      }
      if (source != null) return source;
    }
    throw const PlaybackResolutionException('Next episode is unavailable.');
  }

  void _cancelNextExtraction() {
    _extractionGeneration++;
    final request = _extraction;
    if (request == null) return;
    request.complete(null);
    if (mounted) setState(() => _extraction = null);
  }

  Future<void> _playNext(PlaybackContext context, PlaybackSource source) async {
    if (_closing) throw StateError('Player closed');
    final currentValue = _controller.videoPlayerValue;
    final currentDuration = currentValue?.duration;
    if (currentValue != null &&
        currentDuration != null &&
        currentDuration > Duration.zero) {
      await _persistEpisodeProgress(
        currentValue.position,
        currentDuration,
        completed: false,
        force: true,
      );
    }
    await _controller.pause();
    if (_closing) throw StateError('Player closed');
    await _controller.setupDataSource(_dataSource(source));
    if (_closing) throw StateError('Player closed');
    if (_controller.videoPlayerValue?.hasError == true) {
      throw const PlaybackResolutionException('Next episode could not start.');
    }
    await _controller.play();
    if (Get.isRegistered<RecentWatchManager>()) {
      try {
        await Get.find<RecentWatchManager>()
            .addAnimeToRecent(context.toRecent());
      } catch (_) {/* History failure must not restart a playing video. */}
    }
    _lastSavedProgressKey = null;
    _lastSavedProgressMillis = -1;
  }

  Widget _playerSurface(Widget player) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          player,
          NextEpisodeOverlay(controller: _nextEpisode),
        ]),
      );

  @override
  Widget build(BuildContext context) => Stack(children: [
        _playerSurface(BetterPlayer(controller: _controller)),
        if (_extraction case final request?)
          Offstage(
              child: SizedBox(
            width: 1,
            height: 1,
            child: HlsExtractorWebView(
              key: ObjectKey(request),
              playerUrl: request.url,
              referrerUrl: request.episodeUrl,
              onSourceFound: request.complete,
              onFailure: () => request.complete(null),
            ),
          )),
      ]);

  @override
  void dispose() {
    final currentValue = _controller.videoPlayerValue;
    final currentDuration = currentValue?.duration;
    if (currentValue != null &&
        currentDuration != null &&
        currentDuration > Duration.zero) {
      unawaited(_persistEpisodeProgress(
        currentValue.position,
        currentDuration,
        completed: false,
        force: true,
      ));
    }
    _closing = true;
    _extraction?.complete(null);
    _nextEpisode.dispose();
    _endingService.close();
    _subtitleService.close();
    _controller.dispose(forceDispose: true);
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]));
    super.dispose();
  }
}

class _ExtractionRequest {
  _ExtractionRequest(this.url, this.episodeUrl);
  final String url;
  final String episodeUrl;
  final result = Completer<PlaybackSource?>();
  void complete(PlaybackSource? source) {
    if (!result.isCompleted) result.complete(source);
  }
}
