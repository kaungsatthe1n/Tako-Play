import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../helpers/recent_watch_manager.dart';
import '../models/anime.dart';
import '../models/recent_anime.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class RecentlyAddedAnimeCard extends StatelessWidget {
  const RecentlyAddedAnimeCard({
    Key? key,
    required this.anime,
  }) : super(key: key);

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final RecentWatchManager recentWatchManager = Get.find();
    return GestureDetector(
      onTap: () {
        final recentAnime = RecentAnime(
          id: anime.id.toString(),
          name: anime.name.toString(),
          currentEp: anime.currentEp.toString(),
          imageUrl: anime.imageUrl.toString(),
          epUrl: anime.animeUrl.toString(),
        );
        // Add to Recent Anime List
        recentWatchManager.addAnimeToRecent(recentAnime);
        Get.toNamed(Routes.mediaFetchScreen,
            arguments: {'animeUrl': anime.animeUrl.toString()});
      },
      child: AspectRatio(
        aspectRatio: 3 / 6,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          margin: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      key: UniqueKey(),
                      height: 200,
                      width: 180,
                      cacheManager: CustomCacheManager.instance,
                      fit: BoxFit.cover,
                      imageUrl: anime.imageUrl.toString(),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    height: 200,
                    width: 180,
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 38,
                    ),
                  ),
                  Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tkGradientBlue.withOpacity(.85),
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15)),
                        ),
                        child: Text(
                          anime.currentEp.toString(),
                          style: TakoTheme.darkTextTheme.subtitle1,
                        ),
                      ))
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Flexible(
                child: Text(
                  anime.name.toString(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TakoTheme.darkTextTheme.bodyText1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
