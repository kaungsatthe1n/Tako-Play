import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                          top: 20,
                          left: 20,
                          right: 20,
                          bottom: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          height: screenHeight * .28,
                                          width: screenWidth * .4,
                                          imageUrl: Get
                                              .arguments['anime'].imageUrl
                                              .toString()),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Flexible(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 15),
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
                                margin: const EdgeInsets.symmetric(
                                    vertical: 40, horizontal: 10),
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
                                    return Material(
                                      borderRadius: BorderRadius.circular(10),
                                      color: tkLightGreen.withAlpha(200),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          Get.toNamed(Routes.videoPlayerScreen,
                                              arguments: {
                                                'episodeUrl': list[index]
                                                    .episodeUrl
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
                                                  BorderRadius.circular(10)),
                                          child: Text(
                                            (index + 1).toString(),
                                            style: TakoTheme
                                                .darkTextTheme.headline6,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: screenHeight * .05,
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
