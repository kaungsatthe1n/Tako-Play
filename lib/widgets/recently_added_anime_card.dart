import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/cache_manager.dart';
import 'package:tako_play/helpers/recent_watch_manager.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/models/recent_anime.dart';
import 'package:tako_play/theme/tako_theme.dart';
import 'package:tako_play/utils/constants.dart';
import 'package:tako_play/utils/routes.dart';

class RecentlyAddedAnimeCard extends StatelessWidget {
  const RecentlyAddedAnimeCard({
    Key? key,
    required this.itemHeight,
    required this.itemWidth,
    required this.anime,
  }) : super(key: key);

  final double itemHeight;
  final double itemWidth;
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
          padding: EdgeInsets.symmetric(vertical: 10.h),
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  key: UniqueKey(),
                  height: itemHeight.toDouble().h,
                  width: itemWidth.w,
                  cacheManager: CustomCacheManager.instance,
                  fit: BoxFit.cover,
                  imageUrl: anime.imageUrl.toString(),
                ),
              ),
              SizedBox(
                height: (screenHeight * .02).h,
              ),
              Flexible(
                child: Text(
                  anime.name.toString(),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  style: TakoTheme.darkTextTheme.bodyText2,
                ),
              ),
              Text(
                anime.currentEp.toString(),
                style: TakoTheme.darkTextTheme.bodyText1!.copyWith(
                  color: tkLightGreen,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
