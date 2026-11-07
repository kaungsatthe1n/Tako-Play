import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(Routes.videoListScreen, arguments: {'anime': anime}),
      child: Container(
        height: 126,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: tkDarkBlue,
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: anime.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      key: ValueKey(anime.imageUrl),
                      cacheManager: CustomCacheManager.instance,
                      width: 94,
                      height: 126,
                      fit: BoxFit.cover,
                      imageUrl: anime.imageUrl,
                    )
                  : Container(
                      width: 94,
                      height: 126,
                      color: tkGrey,
                      child: const Icon(Icons.movie_outlined,
                          color: Colors.white54),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 17, 14, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.name.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        Icon(Icons.play_circle_outline_rounded,
                            color: tkCoral, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Watch movie',
                          style: TextStyle(
                            color: tkMutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
