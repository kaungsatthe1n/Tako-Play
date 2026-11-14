import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../models/anime.dart';
import '../models/bookmark.dart';
import '../models/playback_context.dart';
import '../models/recent_anime.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/anime_detail_header.dart';
import '../widgets/cache_image_with_cachemanager.dart';
import '../widgets/plot_summary.dart';
import '../widgets/tako_loading_indicator.dart';
import '../widgets/tako_scaffold.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final RecentWatchManager recentWatchManager = Get.find();
  final BookMarkManager bookMarkManager = Get.find();
  late final Anime _routeAnime;
  late final String name;
  late final String imageUrl;
  late final String animeUrl;
  late final AnimeService _animeService;
  Anime? _cachedAnimeDetails;
  late Future<Anime> _animeDetails;
  bool hasRemainingEp = false;
  int remainingEp = 0;
  int totalChipCount = 0;
  RxList<Episode> epChunkList = <Episode>[].obs;
  Timer? _rangeAnimationTimer;
  var _animateEpisodeTiles = false;
  String start = '';
  String end = '';
  int finalChipCount = 0;
  var selectedChipIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    final routeArguments = Map<String, dynamic>.from(Get.arguments as Map);
    _routeAnime = routeArguments['anime'] as Anime;
    name = _routeAnime.name;
    imageUrl = _routeAnime.imageUrl;
    animeUrl = _routeAnime.animeUrl;
    _animeService = AnimeService(
      requestService: Get.find<RequestService>(),
    );
    _cachedAnimeDetails = _animeService.cachedAnimeDetails(animeUrl);
    if (_cachedAnimeDetails != null) {
      _prepareEpisodeState(_cachedAnimeDetails!);
    }
    // Episode selection is shared with playback history, including when the
    // user opens this title before visiting the Watchlist tab.
    recentWatchManager.loadRecentAnimeFromDatabase();
    _animeDetails = _loadAnimeDetails();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<Anime> _loadAnimeDetails() async {
    final anime = await _animeService.fetchAnimeDetails(animeUrl);
    _prepareEpisodeState(anime);
    return anime;
  }

  void _prepareEpisodeState(Anime anime) {
    unawaited(recentWatchManager.loadEpisodeProgressForAnime(anime.id));
    final episodes = anime.episodes;
    final episodeCount = episodes.length;
    hasRemainingEp = episodeCount % 50 != 0;
    remainingEp = episodeCount % 50;
    totalChipCount = (episodeCount / 50).ceil();
    finalChipCount = totalChipCount;
    final lastChipIndex = totalChipCount > 0 ? totalChipCount - 1 : 0;
    final activeChipIndex =
        selectedChipIndex.value.clamp(0, lastChipIndex).toInt();
    if (activeChipIndex != selectedChipIndex.value) {
      selectedChipIndex.value = activeChipIndex;
    }
    final rangeStart = activeChipIndex * 50;
    final rangeEnd = (rangeStart + 50).clamp(0, episodeCount).toInt();
    epChunkList.value =
        episodes.sublist(rangeStart, rangeEnd).toList(growable: false);
  }

  void _retryAnimeDetails() {
    final animeDetails = _loadAnimeDetails();
    setState(() {
      _animeDetails = animeDetails;
    });
  }

  @override
  void dispose() {
    _rangeAnimationTimer?.cancel();
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      // Get.arguments belongs to whichever route is currently transitioning.
      // Keep the detail route's title locally so an iOS back-swipe cannot
      // replace it with null while this Hero rebuilds.
      tag: _routeAnime.id,
      child: TakoScaffoldWithBackButton(
        appBarTitle: 'Player',
        extendBodyBehindAppBar: true,
        body: FutureBuilder<Anime>(
            future: _animeDetails,
            initialData: _cachedAnimeDetails,
            builder: (context, snapshot) {
              final anime = snapshot.data;
              if (anime != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    buildBackgroundImage(imageUrl),
                    buildBackdropFilter(),
                    buildAnimeDetailsListView(anime, name, imageUrl),
                  ],
                );
              } else {
                return snapshot.hasError
                    ? buildErrorWidget()
                    : buildLoadingWidget();
              }
            }),
      ),
    );
  }

  Widget buildBackgroundImage(String imageUrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: RepaintBoundary(
        child: NetworkImageWithCacheManager(imageUrl: imageUrl),
      ),
    );
  }

  Widget buildBackdropFilter() {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCA090A12), Color(0xEF090A12), Color(0xFF090A12)],
            stops: [0, .35, 1],
          ),
        ),
      ),
    );
  }

  Widget buildAnimeDetailsListView(Anime anime, String name, String imageUrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 14,
          16,
          32,
        ),
        children: [
          AnimeDetailHeader(
            anime: anime,
            name: name,
            imageUrl: imageUrl,
          ),
          const SizedBox(height: 18),
          _buildPlaybackActionRow(anime),
          const SizedBox(height: 14),
          PlotSummary(
            summary: anime.summary,
          ),
          const SizedBox(height: 22),
          buildEpisodeInfoRow(anime),
          const SizedBox(height: 14),
          buildEpisodeChipListView(anime),
          if (anime.episodes.length > 50) const SizedBox(height: 8),
          buildEpisodesGridView(anime),
        ],
      ),
    );
  }

  Widget buildEpisodeInfoRow(Anime anime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Episodes',
            style: TakoTheme.darkTextTheme.headlineSmall?.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            )),
        const Text('Choose where to start',
            style: TextStyle(color: tkMutedText, fontSize: 12)),
      ],
    );
  }

  Widget _buildPlaybackActionRow(Anime anime) => Row(
        children: [
          Expanded(
            child: GetBuilder<RecentWatchManager>(
              builder: (manager) {
                final recent = manager.currentEpisodeFor(anime.id);
                final resumeIndex = recent == null
                    ? -1
                    : anime.episodes.indexWhere(
                        (episode) => episode.link == recent.epUrl,
                      );
                final episode = anime.episodes.isEmpty
                    ? null
                    : anime.episodes[resumeIndex >= 0 ? resumeIndex : 0];
                final label = episode == null
                    ? 'Episodes unavailable'
                    : resumeIndex >= 0
                        ? 'Resume Episode ${episode.number}'
                        : 'Play Episode ${episode.number}';
                return FilledButton.icon(
                  onPressed: episode == null
                      ? null
                      : () => _playEpisode(anime, episode),
                  style: FilledButton.styleFrom(
                    backgroundColor: tkGradientBlue,
                    foregroundColor: tkDarkerBlue,
                    minimumSize: const Size(0, 56),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 23),
                  label: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TakoTheme.darkTextTheme.titleLarge?.copyWith(
                      color: tkDarkerBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          GetBuilder<BookMarkManager>(
            builder: (manager) {
              final saved = manager.ids.contains(anime.id);
              return Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onBookmarkButtonPressed(anime, name),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 23,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );

  Future<void> _playEpisode(Anime anime, Episode episode) async {
    await recentWatchManager.loadEpisodeProgressForAnime(anime.id);
    final progress = recentWatchManager.progressFor(anime.id, episode.link);
    final resumePosition = progress == null || progress.percentage >= 100
        ? null
        : Duration(milliseconds: progress.positionMillis);
    final recentAnime = RecentAnime(
      id: anime.id,
      name: name,
      currentEp: 'Episode ${episode.number}',
      imageUrl: imageUrl,
      epUrl: episode.link,
      animeUrl: animeUrl,
    );
    await recentWatchManager.addAnimeToRecent(recentAnime);
    await Get.toNamed(Routes.mediaFetchScreen, arguments: {
      'animeUrl': episode.link,
      'resumePosition': resumePosition,
      'playbackContext': PlaybackContext(
        id: anime.id,
        name: name,
        imageUrl: imageUrl,
        animeUrl: animeUrl,
        episodes: anime.episodes,
        index: anime.episodes.indexOf(episode),
      ),
    });
  }

  Future<void> onBookmarkButtonPressed(Anime anime, String name) async {
    final item = BookMark(
      id: anime.id,
      imageUrl: imageUrl,
      name: name,
      animeUrl: animeUrl,
    );
    if (bookMarkManager.ids.contains(anime.id.toString())) {
      await bookMarkManager.removeFromBookMarks(item);
      Get.snackbar(
        name,
        'Removed from bookmark successfully!',
        backgroundColor: Colors.black38,
        duration: const Duration(milliseconds: 1300),
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      await bookMarkManager.addToBookMarks(item);
      Get.snackbar(
        name,
        'Added to bookmark successfully!',
        backgroundColor: Colors.black38,
        duration: const Duration(milliseconds: 1300),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget buildEpisodeChipListView(Anime anime) {
    return anime.episodes.length > 50
        ? SizedBox(
            height: 46,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: finalChipCount,
              itemBuilder: (context, index) => buildEpisodeChip(anime, index),
              scrollDirection: Axis.horizontal,
            ),
          )
        : const SizedBox.shrink();
  }

  Widget buildEpisodeChip(Anime anime, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 8),
      child: InkWell(
        onTap: () => onEpisodeChipTapped(anime, index),
        child: Obx(
          () => Chip(
            shadowColor: tkGradientBlack,
            backgroundColor:
                selectedChipIndex.value == index ? tkGradientBlue : tkDarkBlue,
            side: BorderSide(
                color: selectedChipIndex.value == index
                    ? Colors.transparent
                    : Colors.white10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            label: Text(
              getEpisodeRange(index),
              style: TextStyle(
                color: selectedChipIndex.value == index
                    ? Colors.white
                    : tkMutedText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onEpisodeChipTapped(Anime anime, int index) {
    if (selectedChipIndex.value == index) return;

    selectedChipIndex.value = index;
    _animateEpisodeTiles = true;
    _rangeAnimationTimer?.cancel();
    _rangeAnimationTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _animateEpisodeTiles = false);
    });
    getEpisodeRange(index);
    if (finalChipCount == (index + 1)) {
      epChunkList.value = anime.episodes.sublist(int.parse(start) - 1);
    } else {
      epChunkList.value =
          anime.episodes.sublist(int.parse(start) - 1, int.parse(end));
    }
  }

  Widget buildEpisodesGridView(Anime anime) {
    return anime.episodes.isNotEmpty
        ? Obx(
            () => ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: epChunkList.length,
              itemBuilder: (BuildContext context, int index) =>
                  _buildEpisodeTileItem(anime, index),
              separatorBuilder: (context, index) => const SizedBox(height: 9),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Text('Episodes coming soon',
                style: TakoTheme.darkTextTheme.titleSmall),
          );
  }

  Widget _buildEpisodeTileItem(Anime anime, int index) {
    final tile = Obx(() => buildEpisodeTile(anime, index));
    final key = ValueKey(epChunkList[index].link);
    if (!_animateEpisodeTiles) {
      return KeyedSubtree(key: key, child: tile);
    }

    return TweenAnimationBuilder<double>(
      key: key,
      duration: Duration(milliseconds: 180 + (index.clamp(0, 12).toInt() * 22)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      child: tile,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }

  Widget buildEpisodeTile(Anime anime, int index) {
    final episode = epChunkList[index];
    return GetBuilder<RecentWatchManager>(
      builder: (manager) {
        final isCurrentEpisode =
            manager.currentEpisodeFor(anime.id)?.epUrl == episode.link;
        final progress = manager.progressFor(anime.id, episode.link);
        final percentage = progress?.percentage ?? 0;
        final isComplete = percentage >= 100;
        return Material(
          borderRadius: BorderRadius.circular(18),
          color: isCurrentEpisode
              ? const Color(0xFF19172E)
              : const Color(0xFF12121D),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _playEpisode(anime, episode),
            splashColor: Colors.white10,
            child: Container(
              constraints: const BoxConstraints(minHeight: 75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCurrentEpisode
                      ? tkGradientBlue
                      : const Color(0xFF29263F),
                  width: isCurrentEpisode ? 1.4 : 1,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrentEpisode
                          ? tkGradientBlue
                          : isComplete
                              ? tkGradientBlue.withValues(alpha: .2)
                              : const Color(0xFF211F39),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: isComplete
                        ? Icon(Icons.check_rounded,
                            color: isCurrentEpisode
                                ? tkDarkerBlue
                                : tkGradientBlue,
                            size: 21)
                        : Text(
                            episode.number,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TakoTheme.darkTextTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                              color:
                                  isCurrentEpisode ? tkDarkerBlue : tkMutedText,
                            ),
                          ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Episode ${episode.number}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TakoTheme.darkTextTheme.bodyMedium!
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isCurrentEpisode) ...[
                              const SizedBox(width: 6),
                              const Text('LAST PLAYED',
                                  style: TextStyle(
                                      color: Color(0xFFA89BFF),
                                      fontSize: 12,
                                      letterSpacing: .7,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: progress == null ? 0 : percentage / 100,
                            backgroundColor: const Color(0xFF29263F),
                            valueColor: AlwaysStoppedAnimation<Color>(isComplete
                                ? const Color(0xFF68C9A0)
                                : tkGradientBlue),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          progress == null
                              ? 'Not watched'
                              : isComplete
                                  ? 'Completed'
                                  : '$percentage% watched',
                          style: const TextStyle(
                            color: tkMutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isComplete
                        ? Icons.check_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    color: isCurrentEpisode
                        ? const Color(0xFFA89BFF)
                        : const Color(0xFFA6A3C4),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'We could not load the episode list.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _retryAnimeDetails,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingWidget() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          right: 0,
          child: NetworkImageWithCacheManager(
            imageUrl: imageUrl,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xD6090A12), Color(0xFF090A12)],
            ),
          ),
        ),
        const Center(child: TakoLoadingIndicator()),
      ],
    );
  }

  String getEpisodeRange(int index) {
    start = ((index * 50) + 1).toString();
    end = ((50 * (index + 1))).toString();
    if (index == finalChipCount - 1 && hasRemainingEp) {
      end = ((50 * index) + remainingEp).toString();
    }
    // startVal = start;
    // endVal = (int.parse(end) + 1).toString();
    return ('$start - $end');
  }
}
