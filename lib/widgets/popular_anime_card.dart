import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../theme/tako_theme.dart';
import '../utils/routes.dart';

class PopularAnimeCard extends StatelessWidget {
  const PopularAnimeCard({
    Key? key,
    required this.anime,
  }) : super(key: key);


  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: anime.id.toString(),
      child: GestureDetector(
        onTap: () {
          Get.toNamed(Routes.videoListScreen, arguments: {
            'anime': anime,
          });
        },
        child: AspectRatio(
          aspectRatio: 3 / 6,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    key: UniqueKey(),
                    cacheManager: CustomCacheManager.instance,
                    height: 200,
                    width: 180,
                    fit: BoxFit.cover,
                    imageUrl: anime.imageUrl.toString(),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Flexible(
                  child: Text(
                    anime.name.toString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TakoTheme.darkTextTheme.bodyText1!
                        .copyWith(decoration: TextDecoration.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
