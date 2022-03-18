import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/tako_theme.dart';
import '../utils/routes.dart';
import 'cache_image_with_cachemanager.dart';

class RecentAnimeCard extends StatelessWidget {
  const RecentAnimeCard({
    Key? key,
    required this.currentEp,
    required this.epUrl,
    required this.name,
    required this.imageUrl,
    // required this.animeUrl,
    required this.id,
  }) : super(key: key);
  final String id;
  final String name;
  final String currentEp;
  final String imageUrl;
  final String epUrl;
  // final String animeUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6), color: Colors.black38),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onLongPress: () {},
          onTap: () {
            Get.toNamed(Routes.mediaFetchScreen, arguments: {
              'animeUrl': epUrl,
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: NetworkImageWithCacheManager(
                        imageUrl: imageUrl,
                      ),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 12),
                            child: Text(
                              name,
                              style: TakoTheme.darkTextTheme.headline3!
                                  .copyWith(fontSize: 18.0),
                              maxLines: 2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 12),
                            child: Text(
                              currentEp,
                              style: TakoTheme.darkTextTheme.subtitle2!
                                  .copyWith(
                                      color: const Color(0xFF58E6DE),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: IconButton(
                  onPressed: () {
                    Get.toNamed(Routes.mediaFetchScreen, arguments: {
                      'animeUrl': epUrl,
                    });
                  },
                  icon: const Icon(Icons.play_arrow),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
