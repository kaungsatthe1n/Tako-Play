import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../helpers/cache_manager.dart';
import '../models/bookmark.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../models/anime.dart';
import '../services/anime_service.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var selectedIndex = 9999999.obs;
  var isExpanded = false.obs;
  final name = Get.arguments['anime'].name.toString();
  final imageUrl = Get.arguments['anime'].imageUrl.toString();

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
          centerTitle: true,
        ),
        body: FutureBuilder<Anime>(
            future: AnimeService()
                .fetchAnimeDetails(Get.arguments['anime'].animeUrl.toString()),
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
                      child: CachedNetworkImage(
                        key: UniqueKey(),
                        cacheManager: CustomCacheManager.instance,
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
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
                              SizedBox(
                                height: screenHeight * .30,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 0.5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                            key: UniqueKey(),
                                            fit: BoxFit.cover,
                                            cacheManager:
                                                CustomCacheManager.instance,
                                            // height: (screenHeight * .15).h,
                                            // width: (screenWidth * .30).w,
                                            imageUrl: imageUrl),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20.w,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 15.h),
                                            child: Text(name,
                                                style: TakoTheme
                                                    .darkTextTheme.headline4!
                                                    .copyWith()),
                                          ),
                                          Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                              child: Text.rich(
                                                TextSpan(children: [
                                                  TextSpan(
                                                      text: 'Released: ',
                                                      style: TakoTheme
                                                          .darkTextTheme
                                                          .bodyText2),
                                                  TextSpan(
                                                      text: anime!.releasedDate
                                                          .toString(),
                                                      style: TakoTheme
                                                          .darkTextTheme
                                                          .bodyText1),
                                                ]),
                                              )),
                                          Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                              child: Text.rich(
                                                TextSpan(children: [
                                                  TextSpan(
                                                      text: 'Status: ',
                                                      style: TakoTheme
                                                          .darkTextTheme
                                                          .bodyText2),
                                                  TextSpan(
                                                      text: anime.status
                                                          .toString(),
                                                      style: TakoTheme
                                                          .darkTextTheme
                                                          .bodyText1),
                                                ]),
                                              )),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Expanded(
                                            child: Wrap(
                                              children: anime.genres!
                                                  .map((genre) => Transform(
                                                        transform:
                                                            Matrix4.identity()
                                                              ..scale(0.8),
                                                        child: Chip(
                                                            materialTapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            label: Text(genre
                                                                .toString())),
                                                      ))
                                                  .toList(),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 40.h,
                              ),
                              ExpansionTile(
                                textColor: tkLightGreen,
                                iconColor: tkLightGreen,
                                title: const Text('Plot Summary'),
                                childrenPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      anime.summary.toString(),
                                    ),
                                  ),
                                ],
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
                                    Consumer<BookMarkProvider>(
                                      builder: (context, bookMarkProvider, _) =>
                                          TextButton.icon(
                                              onPressed: () {
                                                final item = BookMark(
                                                  id: anime.id!,
                                                  imageUrl: Get
                                                      .arguments['anime']
                                                      .imageUrl
                                                      .toString(),
                                                  name: Get
                                                      .arguments['anime'].name
                                                      .toString(),
                                                  animeUrl: Get
                                                      .arguments['anime']
                                                      .animeUrl
                                                      .toString(),
                                                );
                                                if (bookMarkProvider.ids
                                                    .contains(
                                                        anime.id.toString())) {
                                                  bookMarkProvider
                                                      .removeFromBookMarks(
                                                          item);
                                                  Get.snackbar(name,
                                                      'Removed from bookmark successfully!',
                                                      backgroundColor:
                                                          Colors.black38,
                                                      duration: const Duration(
                                                          milliseconds: 1300),
                                                      snackPosition:
                                                          SnackPosition.BOTTOM);
                                                } else {
                                                  bookMarkProvider
                                                      .addToBookMarks(item);
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
                                                bookMarkProvider.ids
                                                        .contains(anime.id)
                                                    ? Icons.bookmark
                                                    : Icons
                                                        .bookmark_border_outlined,
                                                color: Colors.yellowAccent,
                                              ),
                                              label: Text(
                                                'BookMark',
                                                style: TakoTheme
                                                    .darkTextTheme.bodyText1!
                                                    .copyWith(
                                                        color: Colors
                                                            .yellowAccent),
                                              )),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 20.h),
                                child: const Divider(),
                              ),
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
                      child: CachedNetworkImage(
                        key: UniqueKey(),
                        cacheManager: CustomCacheManager.instance,
                        imageUrl: Get.arguments['anime'].imageUrl.toString(),
                        fit: BoxFit.cover,
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
