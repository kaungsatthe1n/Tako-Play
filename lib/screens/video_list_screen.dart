import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../models/anime.dart';
import '../models/bookmark.dart';
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
  var selectedIndex = 9999999.obs;
  late final Anime _routeAnime;
  late final String name;
  late final String imageUrl;
  late final String animeUrl;
  late Future<Anime> _animeDetails;
  bool hasRemainingEp = false;
  int remainingEp = 0;
  int totalChipCount = 0;
  RxList<Episode> epChunkList = <Episode>[].obs;
  String start = '';
  String end = '';
  int finalChipCount = 0;
  var selectedChipIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _routeAnime = Get.arguments['anime'] as Anime;
    name = _routeAnime.name;
    imageUrl = _routeAnime.imageUrl;
    animeUrl = _routeAnime.animeUrl;
    _animeDetails = _loadAnimeDetails();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<Anime> _loadAnimeDetails() async {
    final anime = await AnimeService(
      requestService: Get.find<RequestService>(),
    ).fetchAnimeDetails(animeUrl);
    _prepareEpisodeState(anime);
    return anime;
  }

  void _prepareEpisodeState(Anime anime) {
    final episodes = anime.episodes;
    final episodeCount = episodes.length;
    hasRemainingEp = episodeCount % 50 != 0;
    remainingEp = episodeCount % 50;
    totalChipCount = (episodeCount / 50).ceil();
    finalChipCount = totalChipCount;
    epChunkList.value = episodes.take(50).toList(growable: false);
  }

  void _retryAnimeDetails() {
    final animeDetails = _loadAnimeDetails();
    setState(() {
      _animeDetails = animeDetails;
    });
  }

  @override
  void dispose() {
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
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return buildErrorWidget();
              }
              if (snapshot.connectionState == ConnectionState.done) {
                final anime = snapshot.data!;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    buildBackgroundImage(imageUrl),
                    buildBackdropFilter(),
                    buildAnimeDetailsListView(anime, name, imageUrl),
                  ],
                );
              } else {
                return buildLoadingWidget();
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
          PlotSummary(
            summary: anime.summary,
          ),
          buildEpisodeInfoRow(anime, name),
          const SizedBox(height: 14),
          buildEpisodeChipListView(anime),
          if (anime.episodes.length > 50) const SizedBox(height: 8),
          buildEpisodesGridView(anime),
        ],
      ),
    );
  }

  Widget buildEpisodeInfoRow(Anime anime, String name) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Episodes',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Choose where to start',
                  style: TextStyle(color: tkMutedText, fontSize: 12)),
            ],
          ),
          GetBuilder<BookMarkManager>(
            builder: (_) => TextButton.icon(
              onPressed: () async => await onBookmarkButtonPressed(anime, name),
              icon: Icon(
                bookMarkManager.ids.contains(anime.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border_outlined,
                color: Colors.white,
              ),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
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
    selectedChipIndex.value = index;
    selectedIndex.value = 99999999;
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
            () => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                maxCrossAxisExtent: 58,
              ),
              itemCount: epChunkList.length,
              itemBuilder: (BuildContext context, int index) =>
                  buildAnimatedEpisodeTile(anime, index),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Text('Episodes coming soon',
                style: TakoTheme.darkTextTheme.titleSmall),
          );
  }

  Widget buildAnimatedEpisodeTile(Anime anime, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(epChunkList[index].link),
      duration: Duration(milliseconds: 180 + (index.clamp(0, 12).toInt() * 22)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      child: Obx(() => buildEpisodeTile(anime, index)),
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
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: selectedIndex.value == index ? tkGradientBlue : tkDarkBlue,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          selectedIndex.value = index;
          final recentAnime = RecentAnime(
            id: anime.id.toString(),
            name: name,
            currentEp: 'Episode ${epChunkList[index].number}',
            imageUrl: imageUrl,
            epUrl: epChunkList[index].link.toString(),
            // animeUrl: animeUrl,
          );
          // Add to Recent Anime List
          await recentWatchManager.addAnimeToRecent(recentAnime);
          await Get.toNamed(Routes.mediaFetchScreen,
              arguments: {'animeUrl': epChunkList[index].link.toString()});
        },
        splashColor: Colors.white,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            epChunkList[index].number,
            style: TakoTheme.darkTextTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w800,
              color: selectedIndex.value == index ? Colors.white : tkMutedText,
            ),
          ),
        ),
      ),
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
