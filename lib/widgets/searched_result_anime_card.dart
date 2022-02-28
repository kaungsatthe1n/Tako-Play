import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/anime.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/cache_image_with_cachemanager.dart';

class SearchedResultAnimeCard extends StatelessWidget {
  const SearchedResultAnimeCard({
    Key? key,
    required this.anime,
  }) : super(key: key);
  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.videoListScreen,
          arguments: {'anime': anime},
        );
      },
      child: Hero(
        tag: anime.id.toString(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NetworkImageWithCacheManager(
                        imageUrl: anime.imageUrl.toString(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,

                              // Colors.white12,
                              tkGradientBlue,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter),
                      ),
                    ),
                  )
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    anime.name.toString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TakoTheme.darkTextTheme.bodyText1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF133F6E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    anime.releasedDate.toString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TakoTheme.darkTextTheme.bodyText1!
                        .copyWith(color: tkLightGreen),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
