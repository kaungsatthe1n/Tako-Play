import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../helpers/network_manager.dart';
import '../models/anime.dart';
import '../models/github.dart';
import '../screens/no_internet_screen.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../widgets/movie_card.dart';
import '../widgets/popular_anime_card.dart';
import '../widgets/recently_added_anime_card.dart';
import '../widgets/tako_animation.dart';
import '../widgets/update_alert_dialog.dart';
import '../widgets/website_error_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final networkManager = Get.find<NetworkManager>();
  late AnimationController animationController;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    animationController = AnimationController(
        duration: Duration(milliseconds: takoAnimationDuration), vsync: this);
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
        await Get.dialog(UpdateAlertDialog(
          downloadLink: github.downloadLink.toString(),
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestService = Provider.of<RequestService>(context, listen: false);
    // final itemHeight = (screenHeight * .26).h;
    // final itemWidth = (screenWidth / 2).w;
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
                              horizontal: 20, vertical: 20),
                          child: Row(
                            children: [
                              Text(
                                'Popular',
                                style:
                                    TakoTheme.darkTextTheme.headline4!.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(
                                    Icons.local_fire_department_sharp,
                                    color: Colors.orange,
                                    size: 25,
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: popularList!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return AnimatedBuilder(
                                animation: animationController,
                                child: PopularAnimeCard(
                                  anime: popularList[index],
                                ),
                                builder: (context, child) {
                                  return Transform(
                                    transform: Matrix4.translationValues(
                                        -200 *
                                            (1.0 -
                                                TakoCurveAnimation(
                                                        animationController,
                                                        index,
                                                        popularList.length)
                                                    .value),
                                        0,
                                        0),
                                    child: child,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                            top: 10,
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Recently Added ',
                                style:
                                    TakoTheme.darkTextTheme.headline4!.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
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
                          height: 300,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: recentlyAdded!.length,
                            itemBuilder: (BuildContext context, int index) {
                              animationController.forward();
                              return AnimatedBuilder(
                                animation: animationController,
                                child: RecentlyAddedAnimeCard(
                                    anime: recentlyAdded[index]),
                                builder: (context, child) {
                                  return Transform(
                                    transform: Matrix4.translationValues(
                                        -200 *
                                            (1.0 -
                                                TakoCurveAnimation(
                                                        animationController,
                                                        index,
                                                        recentlyAdded.length)
                                                    .value),
                                        0,
                                        0),
                                    child: child,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Row(
                            children: [
                              Text(
                                'Movies',
                                style:
                                    TakoTheme.darkTextTheme.headline4!.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
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
