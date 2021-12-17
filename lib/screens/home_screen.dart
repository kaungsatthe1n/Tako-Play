import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
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
              height: 18.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: Text('Tako-Play',
                        style: TakoTheme.darkTextTheme.headline3),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Text('New Update is available',
                        style: TakoTheme.darkTextTheme.bodyText1),
                  ),
                  const SizedBox(
                    height: 10,
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
    final itemHeight = 28.h;
    final itemWidth = 100.w / 2;
    return Scaffold(
        key: _formKey,
        drawer: Drawer(
          child: Container(
            color: tkDarkBlue,
            child: ListView(
              children: [
                SizedBox(
                  height: 40.h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          height: 7.h,
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
                  height: 2.h,
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
                    SizedBox(height: 5.h),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Text(
                          'Popular',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40.h,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  width: itemWidth * .75,
                                  child: Flex(
                                    direction: Axis.vertical,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                          height: itemHeight.toDouble(),
                                          width: itemWidth,
                                          fit: BoxFit.cover,
                                          imageUrl: popularList[index]
                                              .imageUrl
                                              .toString(),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 2.h,
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
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Text(
                          'Recently Added ',
                          style: TakoTheme.darkTextTheme.headline4!.copyWith(
                            color: tkLightGreen,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40.h,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                width: itemWidth * .75,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: CachedNetworkImage(
                                        height: itemHeight.toDouble(),
                                        width: itemWidth,
                                        fit: BoxFit.cover,
                                        imageUrl: recentlyAdded[index]
                                            .imageUrl
                                            .toString(),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2.h,
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
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
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
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black12,
                              ),
                              height: 20.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                          width: 110,
                                          imageUrl: anime.imageUrl.toString())),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20, horizontal: 10),
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
