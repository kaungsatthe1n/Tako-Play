import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/popular_anime_card.dart';
import '../widgets/recently_added_anime_card.dart';
import '../widgets/website_error_widget.dart';
import '../models/anime.dart';
import '../models/github.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../helpers/network_manager.dart';
import '../screens/no_internet_screen.dart';
import '../widgets/update_alert_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final networkManager = Get.find<NetworkManager>();
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
        Get.dialog(UpdateAlertDialog(
          downloadLink: github.downloadLink.toString(),
        ));
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
    return GetBuilder<NetworkManager>(
      builder: (_) => networkManager.isOnline
          ? FutureBuilder<List<AnimeResults>>(
              future: Future.wait([
                AnimeService()
                    .getAnimes(requestService.requestPopularResponse()),
                AnimeService().getRecentlyAddedAnimes(),
                AnimeService()
                    .getAnimes(requestService.requestMoviesResponse()),
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const WebsiteErrorWidget();
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
                          margin: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 20.h),
                          child: Row(
                            children: [
                              Text(
                                'Popular',
                                style:
                                    TakoTheme.darkTextTheme.headline4!.copyWith(
                                  color: tkLightGreen,
                                ),
                              ),
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.w),
                                  child: const Icon(
                                    Icons.local_fire_department_sharp,
                                    color: Colors.orange,
                                    size: 25,
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: (screenHeight * .39).h,
                          child: AnimationLimiter(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              scrollDirection: Axis.horizontal,
                              itemCount: popularList!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -80,
                                    // verticalOffset: 100,
                                    child: FadeInAnimation(
                                      child: PopularAnimeCard(
                                        itemHeight: itemHeight,
                                        itemWidth: itemWidth,
                                        anime: popularList[index],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
                                style:
                                    TakoTheme.darkTextTheme.headline4!.copyWith(
                                  color: tkLightGreen,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: const Icon(
                                  Icons.bubble_chart_rounded,
                                  color: Color(0xFF58E6DE),
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: (screenHeight * .39).h,
                          child: AnimationLimiter(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              scrollDirection: Axis.horizontal,
                              itemCount: recentlyAdded!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -80,
                                    // verticalOffset: 100,
                                    child: FadeInAnimation(
                                      child: RecentlyAddedAnimeCard(
                                          itemHeight: itemHeight,
                                          itemWidth: itemWidth,
                                          anime: recentlyAdded[index]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 20.h),
                          child: Row(
                            children: [
                              Text(
                                'Movies',
                                style:
                                    TakoTheme.darkTextTheme.headline4!.copyWith(
                                  color: tkLightGreen,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: const Icon(
                                  Icons.movie_creation_sharp,
                                  color: Color(0xFFF5EB64),
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: movieList!.map((anime) {
                            return MovieCard(
                              anime: anime,
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
              })
          : const NoInternetScreen(),
    );
  }
}
