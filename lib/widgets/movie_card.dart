import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({Key? key, required this.anime}) : super(key: key);
  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.videoListScreen, arguments: {
          'anime': anime,
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black26,
        ),
        height: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                key: UniqueKey(),
                cacheManager: CustomCacheManager.instance,
                width: 110,
                imageUrl: anime.imageUrl.toString(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Text(
                      anime.name.toString(),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TakoTheme.darkTextTheme.subtitle2!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Text(
                      anime.releasedDate.toString(),
                      softWrap: true,
                      style: TakoTheme.darkTextTheme.subtitle1!
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
