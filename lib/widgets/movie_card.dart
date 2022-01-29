import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tako_play/helpers/cache_manager.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/theme/tako_theme.dart';
import 'package:tako_play/utils/constants.dart';
import 'package:tako_play/utils/routes.dart';

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
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black26,
        ),
        height: (screenHeight * .2).h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                key: UniqueKey(),
                cacheManager: CustomCacheManager.instance,
                width: 110.w,
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
                        EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
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
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                    child: Text(
                      anime.releasedDate.toString(),
                      softWrap: true,
                      style: TakoTheme.darkTextTheme.subtitle1!
                          .copyWith(color: tkLightGreen),
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
