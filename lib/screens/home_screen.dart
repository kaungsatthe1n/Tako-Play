import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tako_play/helpers/cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/anime.dart';
import '../models/github.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
    try {
      final response =
          await RequestService.create().requestGitHubUpdate(latestRelease);
      final json = jsonDecode(response.body);
      final github = Github.fromJson(json);
      if (version.compareTo(github.version.toString().trim()) == 0) {
        isSameVersion = true;
        // ignore: avoid_print
        print('same version');
      } else {
        isSameVersion = false;
        updateLink = github.downloadLink.toString();
        Get.dialog(AlertDialog(
            elevation: 10,
            backgroundColor: tkDarkBlue,
            content: SizedBox(
              height: (screenHeight * .18).h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin:
                        EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
                    child: Text('Tako-Play',
                        style: TakoTheme.darkTextTheme.headline3),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Text('New Update is available',
                        style: TakoTheme.darkTextTheme.bodyText1),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MaterialButton(
                          elevation: 5,
                          color: tkLightGreen.withAlpha(200),
                          child: const Text('Update'),
                          onPressed: () =>
                              launch(github.downloadLink.toString())),
                    ],
                  ),
                ],
              ),
            )));
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestService = Provider.of<RequestService>(context, listen: false);
    final itemHeight = (screenHeight * .26).h;
    final itemWidth = (screenWidth / 2).w;
    return FutureBuilder<List<AnimeResults>>(
        future: Future.wait([
          AnimeService().getAnimes(requestService.requestPopularResponse()),
          AnimeService().getRecentlyAddedAnimes(),
          AnimeService().getAnimes(requestService.requestMoviesResponse()),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/deku.gif'),
                SizedBox(height: screenHeight * .05),
                Container(
                  margin:
                      EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                  alignment: Alignment.center,
                  child: Text(
                    'Temporarily Down For Maintainance Or No Internet Connection',
                    textAlign: TextAlign.center,
                    style: TakoTheme.darkTextTheme.headline4,
                  ),
                )
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            final popularList = snapshot.data![0].animeList;
            final recentlyAdded = snapshot.data![1].animeList;
            final movieList = snapshot.data![2].animeList;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    child: Row(
                      children: [
                        Text(
                          'Popular',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: const Icon(
                              Icons.bubble_chart_rounded,
                              size: 25,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: (screenHeight * .39).h,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: popularList!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Hero(
                          tag: popularList[index].id.toString(),
                          child: GestureDetector(
                            onTap: () {
                              Get.toNamed(Routes.videoListScreen, arguments: {
                                'anime': popularList[index],
                              });
                            },
                            child: AspectRatio(
                              aspectRatio: 3 / 6,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                margin: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Flex(
                                  direction: Axis.vertical,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: CachedNetworkImage(
                                        key: UniqueKey(),
                                        cacheManager:
                                            CustomCacheManager.instance,
                                        height: itemHeight.toDouble().h,
                                        width: itemWidth.w,
                                        fit: BoxFit.cover,
                                        imageUrl: popularList[index]
                                            .imageUrl
                                            .toString(),
                                      ),
                                    ),
                                    SizedBox(
                                      height: (screenHeight * .02).h,
                                    ),
                                    Flexible(
                                      child: Text(
                                        popularList[index].name.toString(),
                                        maxLines: 3,
                                        textAlign: TextAlign.center,
                                        style: TakoTheme
                                            .darkTextTheme.bodyText1!
                                            .copyWith(
                                                decoration:
                                                    TextDecoration.none),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                      top: 10.h,
                      left: 20.w,
                      right: 20.w,
                      bottom: 20.h,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Recently Added ',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: const Icon(
                            Icons.bedtime,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: (screenHeight * .4).h,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: recentlyAdded!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            Get.toNamed(Routes.mediaFetchScreen, arguments: {
                              'animeUrl':
                                  recentlyAdded[index].animeUrl.toString()
                            });
                          },
                          child: AspectRatio(
                            aspectRatio: 3 / 6,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              margin: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: CachedNetworkImage(
                                      key: UniqueKey(),
                                      height: itemHeight.toDouble().h,
                                      width: itemWidth.w,
                                      cacheManager: CustomCacheManager.instance,
                                      fit: BoxFit.cover,
                                      imageUrl: recentlyAdded[index]
                                          .imageUrl
                                          .toString(),
                                    ),
                                  ),
                                  SizedBox(
                                    height: (screenHeight * .02).h,
                                  ),
                                  Flexible(
                                    child: Text(
                                      recentlyAdded[index].name.toString(),
                                      maxLines: 3,
                                      textAlign: TextAlign.center,
                                      style: TakoTheme.darkTextTheme.bodyText2,
                                    ),
                                  ),
                                  Text(
                                    recentlyAdded[index].currentEp.toString(),
                                    style: TakoTheme.darkTextTheme.bodyText1!
                                        .copyWith(
                                      color: tkLightGreen,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                    child: Row(
                      children: [
                        Text(
                          'Movies',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: const Icon(
                            Icons.movie,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: movieList!.map((anime) {
                      return GestureDetector(
                        onTap: () {
                          Get.toNamed(Routes.videoListScreen, arguments: {
                            'anime': anime,
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.black12,
                          ),
                          height: (screenHeight * .2).h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                      key: UniqueKey(),
                                      cacheManager: CustomCacheManager.instance,
                                      width: 110.w,
                                      imageUrl: anime.imageUrl.toString())),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.h, horizontal: 20.w),
                                      child: Text(
                                        anime.name.toString(),
                                        softWrap: true,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TakoTheme.darkTextTheme.subtitle1,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 20.h, horizontal: 20.w),
                                      child: Text(
                                        anime.releasedDate.toString(),
                                        softWrap: true,
                                        style: TakoTheme
                                            .darkTextTheme.subtitle1!
                                            .copyWith(color: tkLightGreen),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            );
          } else {
            return const Center(
              child: loadingIndicator,
            );
          }
        });
  }
}
