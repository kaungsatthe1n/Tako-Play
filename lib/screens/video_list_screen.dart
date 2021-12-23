import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
        body: FutureBuilder<AnimeResults>(
            future: AnimeService()
                .fetchEpisodes(Get.arguments['anime'].episodeUrl.toString()),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'An error occured',
                    style: TakoTheme.darkTextTheme.headline3,
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.done) {
                final list = snapshot.data!.animeList;
                return SizedBox(
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CachedNetworkImage(
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
                      Positioned(
                          top: 20.h,
                          left: 20.w,
                          right: 20.w,
                          bottom: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 0.6,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            height: (screenHeight * .28).h,
                                            width: (screenWidth * .43).w,
                                            imageUrl: Get
                                                .arguments['anime'].imageUrl
                                                .toString()),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20.w,
                                    ),
                                    Flexible(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                            vertical: 15.h),
                                        child: Text(
                                            Get.arguments['anime'].name
                                                .toString(),
                                            style: TakoTheme
                                                .darkTextTheme.headline4!
                                                .copyWith()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 40.h, horizontal: 10.w),
                                child: Text(
                                  'Episodes',
                                  style: TakoTheme.darkTextTheme.headline5,
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 20,
                                  ),
                                  itemCount: list!.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Obx(
                                      () => Material(
                                        borderRadius: BorderRadius.circular(10),
                                        color: selectedIndex.value == index
                                            ? tkDarkGreen
                                            : tkLightGreen.withAlpha(200),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          onTap: () async {
                                            selectedIndex.value = index;
                                            Get.dialog(
                                              AlertDialog(
                                                backgroundColor: tkDarkBlue,
                                                content: Container(
                                                  alignment: Alignment.center,
                                                  height: screenHeight * .2,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Flexible(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  'Slow',
                                                                  style: TakoTheme
                                                                      .darkTextTheme
                                                                      .bodyText1,
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_circle_down_outlined,
                                                                  color: Colors
                                                                      .red,
                                                                )
                                                              ],
                                                            ),
                                                            MaterialButton(
                                                                elevation: 5,
                                                                color: tkLightGreen
                                                                    .withAlpha(
                                                                        200),
                                                                child: const Text(
                                                                    'CDN Server'),
                                                                onPressed: () {
                                                                  Get.back();
                                                                  Get.toNamed(
                                                                      Routes
                                                                          .mediaFetchScreen,
                                                                      arguments: {
                                                                        'episodeUrl': list[index]
                                                                            .episodeUrl
                                                                            .toString(),
                                                                        'type':
                                                                            'cdn'
                                                                      });
                                                                }),
                                                            Text(
                                                              'No Ads Popup',
                                                              style: TakoTheme
                                                                  .darkTextTheme
                                                                  .subtitle1!
                                                                  .copyWith(
                                                                      color: Colors
                                                                          .green),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  'Fast',
                                                                  style: TakoTheme
                                                                      .darkTextTheme
                                                                      .bodyText1,
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_circle_up_outlined,
                                                                  color: Colors
                                                                      .green,
                                                                )
                                                              ],
                                                            ),
                                                            MaterialButton(
                                                                elevation: 5,
                                                                color: tkLightGreen
                                                                    .withAlpha(
                                                                        200),
                                                                child: const Text(
                                                                    'WebView'),
                                                                onPressed: () {
                                                                  Get.back();
                                                                  Get.toNamed(
                                                                      Routes
                                                                          .mediaFetchScreen,
                                                                      arguments: {
                                                                        'episodeUrl': list[index]
                                                                            .episodeUrl
                                                                            .toString(),
                                                                        'type':
                                                                            'webview'
                                                                      });
                                                                }),
                                                            Text(
                                                              'Ads Popup',
                                                              style: TakoTheme
                                                                  .darkTextTheme
                                                                  .subtitle1!
                                                                  .copyWith(
                                                                      color: Colors
                                                                          .red),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
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
                                                    BorderRadius.circular(10)),
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
                                ),
                              ),
                              SizedBox(
                                height: (screenHeight * .05).h,
                              ),
                            ],
                          )),
                    ],
                  ),
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
