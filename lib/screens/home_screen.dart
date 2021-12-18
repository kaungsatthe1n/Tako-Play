import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    checkForUpdate();
    print(screenHeight);
    print(screenWidth);
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
    return Scaffold(
        key: _formKey,
        drawer: Drawer(
          child: Container(
            color: tkDarkBlue,
            child: ListView(
              children: [
                SizedBox(
                  height: (screenHeight * .39).h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.h),
                          child: Image.asset(
                            'assets/images/rem.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.black45,
                      ),
                      Positioned(
                        right: 5,
                        left: 5,
                        bottom: 0,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          height: (screenHeight * .07).h,
                          decoration: BoxDecoration(
                              color: tkLightGreen.withOpacity(.7),
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10))),
                          child: Text(
                            'TakoPlay',
                            style: TakoTheme.darkTextTheme.headline4,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: (screenHeight * .02).h,
                ),
                ListTile(
                  hoverColor: Colors.white,
                  onTap: () => launch(takoTracker),
                  leading: const Icon(Icons.apps_outlined),
                  title: const Text('Other App'),
                ),
                ListTile(
                  onTap: () => Get.toNamed(Routes.aboutAppScreen),
                  hoverColor: Colors.white,
                  leading: const Icon(Icons.info),
                  title: const Text('About TakoPlay'),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: IconButton(
                  onPressed: () {
                    Get.toNamed(Routes.searchScreen);
                  },
                  icon: const Icon(Icons.search)),
            ),
          ],
          centerTitle: true,
          title: const Text(
            'Watch',
          ),
        ),
        body: FutureBuilder<List<AnimeResults>>(
            future: Future.wait([
              AnimeService().getAnimes(requestService.requestPopularResponse()),
              AnimeService().getAnimes(requestService.fetchHomePage()),
              AnimeService().getAnimes(requestService.requestOnGoingResponse())
            ]),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/deku.gif'),
                    SizedBox(height: screenHeight * .05),
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 20.w),
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
                final ongoingList = snapshot.data![2].animeList;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 20.h),
                        child: Text(
                          'Popular',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: (screenHeight * .39).h,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: popularList!.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Hero(
                              tag: popularList[index].id.toString(),
                              child: GestureDetector(
                                onTap: () {
                                  Get.toNamed(Routes.videoListScreen,
                                      arguments: {'anime': popularList[index]});
                                },
                                child: AspectRatio(
                                  aspectRatio: 3 / 6,
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10.h),
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 10.w),
                                    child: Flex(
                                      direction: Axis.vertical,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: CachedNetworkImage(
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
                        child: Text(
                          'Recently Added ',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: (screenHeight * .4).h,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: recentlyAdded!.length,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                              onTap: () {
                                Get.toNamed(Routes.videoPlayerScreen,
                                    arguments: {
                                      'episodeUrl': recentlyAdded[index]
                                          .episodeUrl
                                          .toString()
                                    });
                              },
                              child: AspectRatio(
                                aspectRatio: 3 / 6,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  margin:
                                      EdgeInsets.symmetric(horizontal: 10.w),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                          height: itemHeight.toDouble().h,
                                          width: itemWidth.w,
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
                                          recentlyAdded[index]
                                              .currentEp
                                              .toString(),
                                          maxLines: 3,
                                          textAlign: TextAlign.center,
                                          style:
                                              TakoTheme.darkTextTheme.bodyText1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 20.h),
                        child: Text(
                          'Ongoing',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                      ),
                      Column(
                        children: ongoingList!.map((anime) {
                          return GestureDetector(
                            onTap: () {
                              Get.toNamed(Routes.videoPlayerScreen, arguments: {
                                'episodeUrl': anime.episodeUrl.toString()
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
                                          width: 110.w,
                                          imageUrl: anime.imageUrl.toString())),
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 20.h, horizontal: 10.w),
                                      child: Text(
                                        anime.currentEp.toString(),
                                        style:
                                            TakoTheme.darkTextTheme.subtitle2,
                                      ),
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
                  child: CircularProgressIndicator(),
                );
              }
            }));
  }
}
