import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../models/anime.dart';
import '../models/bookmark.dart';
import '../models/recent_anime.dart';
import '../services/anime_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/tako_helper.dart';
import '../widgets/anime_detail_header.dart';
import '../widgets/cache_image_with_cachemanager.dart';
import '../widgets/plot_summary.dart';
import '../widgets/tako_animation.dart';
import '../widgets/tako_scaffold.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen>
    with SingleTickerProviderStateMixin {
  final RecentWatchManager recentWatchManager = Get.find();
  final BookMarkManager bookMarkManager = Get.find();
  var selectedIndex = 9999999.obs;
  var isExpanded = false.obs;
  final name = Get.arguments['anime'].name.toString();
  final imageUrl = Get.arguments['anime'].imageUrl.toString();
  final animeUrl = Get.arguments['anime'].animeUrl.toString();
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
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
    animationController = AnimationController(
        duration: Duration(milliseconds: takoAnimationDuration), vsync: this);
    fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(animationController);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    animationController.dispose();
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
      tag: Get.arguments['anime'].id.toString(),
      child: TakoScaffoldWithBackButton(
        appBarTitle: 'Player',
        body: FutureBuilder<Anime>(
            future: AnimeService().fetchAnimeDetails(animeUrl),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return buildErrorWidget();
              }
              if (snapshot.connectionState == ConnectionState.done) {
                final anime = snapshot.data;
                if ((anime!.episodes!.length % 50).floor() < 50) {
                  hasRemainingEp = true;
                  remainingEp = (anime.episodes!.length % 50).floor();
                }
                totalChipCount = (anime.episodes!.length / 50).floor();
                epChunkList.value = anime.episodes!.sublist(
                    0,
                    (hasRemainingEp == true && anime.episodes!.length < 50)
                        ? remainingEp
                        : 50);
                finalChipCount = totalChipCount + (hasRemainingEp ? 1 : 0);

                print('Ep Chunk List ${epChunkList.length}+ $remainingEp');
                // print(epChunkList[1].link.toString());
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
      child: NetworkImageWithCacheManager(
        imageUrl: imageUrl,
      ),
    );
  }

  Widget buildBackdropFilter() {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 8,
        sigmaY: 8,
      ),
      child: Container(
        color: Colors.black87,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget buildAnimeDetailsListView(Anime anime, String name, String imageUrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            AnimeDetailHeader(
              anime: anime,
              name: name,
              imageUrl: imageUrl,
            ),
            SizedBox(height: 40),
            PlotSummary(
              summary: anime.summary.toString(),
            ),
            buildEpisodeInfoRow(anime, name),
            Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: const Divider(),
            ),
            buildEpisodeChipListView(anime),
            buildEpisodesGridView(anime),
          ],
        ),
      ),
    );
  }

  Widget buildEpisodeInfoRow(Anime anime, String name) {
    return Container(
      margin: EdgeInsets.only(top: 40, left: 10, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Episodes',
            style: TakoTheme.darkTextTheme.headlineSmall,
          ),
          GetBuilder<BookMarkManager>(
            builder: (_) => TextButton.icon(
              onPressed: () => onBookmarkButtonPressed(anime, name),
              icon: Icon(
                bookMarkManager.ids.contains(anime.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border_outlined,
                color: Colors.white,
              ),
              label: Text(
                'BookMark',
                style: TakoTheme.darkTextTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onBookmarkButtonPressed(Anime anime, String name) {
    final item = BookMark(
      id: anime.id!,
      imageUrl: imageUrl,
      name: name,
      animeUrl: animeUrl,
    );
    if (bookMarkManager.ids.contains(anime.id.toString())) {
      bookMarkManager.removeFromBookMarks(item);
      Get.snackbar(
        name,
        'Removed from bookmark successfully!',
        backgroundColor: Colors.black38,
        duration: const Duration(milliseconds: 1300),
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      bookMarkManager.addToBookMarks(item);
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
    return anime.episodes!.length > 50
        ? SizedBox(
            height: 70,
            child: ListView.builder(
              itemCount: finalChipCount,
              itemBuilder: (context, index) {
                return buildEpisodeChip(anime, index);
              },
              scrollDirection: Axis.horizontal,
            ),
          )
        : SizedBox();
  }

  Widget buildEpisodeChip(Anime anime, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      child: InkWell(
        onTap: () => onEpisodeChipTapped(anime, index),
        child: Obx(
          () => Chip(
            shadowColor: tkGradientBlack,
            backgroundColor: selectedChipIndex.value == index
                ? tkGradientBlue
                : Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 10),
            label: Text(
              getEpisodeRange(index),
              style: TextStyle(
                color: selectedChipIndex.value == index
                    ? Colors.white
                    : tkGradientBlue,
                fontSize: 17,
                fontWeight: FontWeight.bold,
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
    animationController.reset();
    getEpisodeRange(index);
    if (finalChipCount == (index + 1)) {
      takoDebugPrint('last chip');
      epChunkList.value = anime.episodes!.sublist(int.parse(start) - 1);
    } else {
      epChunkList.value =
          anime.episodes!.sublist(int.parse(start) - 1, int.parse(end));
    }
  }

  Widget buildEpisodesGridView(Anime anime) {
    return anime.episodes!.isNotEmpty
        ? Obx(
            () => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                maxCrossAxisExtent: 50,
              ),
              itemCount: epChunkList.length,
              itemBuilder: (BuildContext context, int index) {
                animationController.forward();
                return buildAnimatedEpisodeTile(anime, index);
              },
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
            child: Text('Coming Soon ..',
                style: TakoTheme.darkTextTheme.titleSmall),
          );
  }

  Widget buildAnimatedEpisodeTile(Anime anime, int index) {
    return Obx(
      () => AnimatedBuilder(
        animation: animationController,
        child: buildEpisodeTile(anime, index),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.translationValues(
              0,
              100 *
                  (1.0 -
                      TakoCurveAnimation(
                              animationController, index, epChunkList.length)
                          .value),
              0,
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget buildEpisodeTile(Anime anime, int index) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: selectedIndex.value == index ? tkGradientBlue : tkGrey,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          print(epChunkList[index].link.toString());
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
          recentWatchManager.addAnimeToRecent(recentAnime);
          await Get.toNamed(Routes.mediaFetchScreen,
              arguments: {'animeUrl': epChunkList[index].link.toString()});
        },
        splashColor: Colors.white,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 2,
                blurRadius: 7,
                offset: Offset(0, 5),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            epChunkList[index].number,
            style: TakoTheme.darkTextTheme.displayMedium
          ),
        ),
      ),
    );
  }

  Widget buildErrorWidget() {
    return Center(
      child: Text(
        'An Error Occurred',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8,
            sigmaY: 8,
          ),
          child: Container(
            color: Colors.black87,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ],
    );
  }

  String getEpisodeRange(int index) {
    start = ((index * 50) + 1).toString();
    end = ((50 * (index + 1))).toString();
    if (index == totalChipCount && hasRemainingEp) {
      end = ((50 * index) + remainingEp).toString();
    }
    // startVal = start;
    // endVal = (int.parse(end) + 1).toString();
    return ('$start - $end');
  }
}
