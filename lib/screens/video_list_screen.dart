import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import '../widgets/anime_detail_header.dart';
import '../widgets/cache_image_with_cachemanager.dart';
import '../widgets/plot_summary.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RecentWatchManager recentWatchManager = Get.find();
  final BookMarkManager bookMarkManager = Get.find();
  var selectedIndex = 9999999.obs;
  var isExpanded = false.obs;
  final name = Get.arguments['anime'].name.toString();
  final imageUrl = Get.arguments['anime'].imageUrl.toString();
  final animeUrl = Get.arguments['anime'].animeUrl.toString();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Get.arguments['anime'].id.toString(),
      child: Scaffold(
        key: _formKey,
        appBar: AppBar(
            title: const Text(
              'Player',
            ),
            leading: IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(Icons.arrow_back_ios_new))),
        body: FutureBuilder<Anime>(
            future: AnimeService().fetchAnimeDetails(animeUrl),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'An Error ccurred',
                    style: TakoTheme.darkTextTheme.headline3,
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.done) {
                final anime = snapshot.data;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
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
                    Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView(
                            children: [
                              AnimeDetailHeader(
                                anime: anime!,
                                name: name,
                                imageUrl: imageUrl,
                              ),
                              SizedBox(
                                height: 40.h,
                              ),
                              PlotSummary(
                                summary: anime.summary.toString(),
                              ),
                              Container(
                                margin: EdgeInsets.only(
                                  top: 40.h,
                                  left: 10.w,
                                  right: 10.w,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Episodes',
                                      style: TakoTheme.darkTextTheme.headline5,
                                    ),
                                    GetBuilder<BookMarkManager>(
                                      builder: (_) => TextButton.icon(
                                          onPressed: () {
                                            final item = BookMark(
                                              id: anime.id!,
                                              imageUrl: imageUrl,
                                              name: name,
                                              animeUrl: animeUrl,
                                            );
                                            if (bookMarkManager.ids.contains(
                                                anime.id.toString())) {
                                              bookMarkManager
                                                  .removeFromBookMarks(item);
                                              //Removed
                                              Get.snackbar(name,
                                                  'Removed from bookmark successfully!',
                                                  backgroundColor:
                                                      Colors.black38,
                                                  duration: const Duration(
                                                      milliseconds: 1300),
                                                  snackPosition:
                                                      SnackPosition.BOTTOM);
                                            } else {
                                              bookMarkManager
                                                  .addToBookMarks(item);
                                              //Add
                                              Get.snackbar(name,
                                                  'Added to bookmark successfully!',
                                                  backgroundColor:
                                                      Colors.black38,
                                                  duration: const Duration(
                                                      milliseconds: 1300),
                                                  snackPosition:
                                                      SnackPosition.BOTTOM);
                                            }
                                          },
                                          icon: Icon(
                                            bookMarkManager.ids
                                                    .contains(anime.id)
                                                ? Icons.bookmark
                                                : Icons
                                                    .bookmark_border_outlined,
                                            color: tkLightGreen,
                                          ),
                                          label: Text(
                                            'BookMark',
                                            style: TakoTheme
                                                .darkTextTheme.bodyText1!
                                                .copyWith(color: tkLightGreen),
                                          )),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 20.h),
                                child: const Divider(),
                              ),
                              // Episodes Grid View
                              anime.epLinks!.isNotEmpty
                                  ? GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 5,
                                        mainAxisSpacing: 20,
                                        crossAxisSpacing: 20,
                                      ),
                                      itemCount: anime.epLinks!.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Obx(
                                          () => Material(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: selectedIndex.value == index
                                                ? tkDarkGreen
                                                : tkLightGreen.withAlpha(200),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              onTap: () async {
                                                selectedIndex.value = index;
                                                final recentAnime = RecentAnime(
                                                  id: anime.id.toString(),
                                                  name: name,
                                                  currentEp:
                                                      'Episode ${index + 1}',
                                                  imageUrl: imageUrl,
                                                  epUrl: anime.epLinks![index]
                                                      .toString(),
                                                  // animeUrl: animeUrl,
                                                );
                                                // Add to Recent Anime List
                                                recentWatchManager
                                                    .addAnimeToRecent(
                                                        recentAnime);
                                                Get.toNamed(
                                                    Routes.mediaFetchScreen,
                                                    arguments: {
                                                      'animeUrl': anime
                                                          .epLinks![index]
                                                          .toString()
                                                    });
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
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: Text(
                                                  (index + 1).toString(),
                                                  style: TakoTheme
                                                      .darkTextTheme.headline6,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        'Coming Soon ..',
                                        style:
                                            TakoTheme.darkTextTheme.subtitle2,
                                      ),
                                    ),
                            ],
                          ),
                        )),
                  ],
                );
              } else {
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
            }),
      ),
    );
  }
}
