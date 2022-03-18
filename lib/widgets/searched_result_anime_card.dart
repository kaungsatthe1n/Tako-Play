import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/anime.dart';
import '../theme/tako_theme.dart';
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
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NetworkImageWithCacheManager(
                        imageUrl: anime.imageUrl.toString(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Tooltip(
                          message: anime.name
                                  .toString()
                                  .isCaseInsensitiveContains('dub')
                              ? 'Dub'
                              : 'Sub',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(Icons.album_rounded,
                              size: 25,
                              color: anime.name
                                      .toString()
                                      .isCaseInsensitiveContains('dub')
                                  ? Colors.orange
                                  : Color.fromARGB(255, 212, 0, 99)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
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
                        .copyWith(color: Colors.white),
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
