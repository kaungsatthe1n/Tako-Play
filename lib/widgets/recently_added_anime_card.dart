import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class RecentlyAddedAnimeCard extends StatelessWidget {
  const RecentlyAddedAnimeCard({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: GestureDetector(
        onTap: () => Get.toNamed(
          Routes.videoListScreen,
          arguments: {'anime': anime},
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: tkDarkBlue,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          key: ValueKey(anime.imageUrl),
                          cacheManager: CustomCacheManager.instance,
                          fit: BoxFit.cover,
                          imageUrl: anime.imageUrl.toString(),
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: tkGrey),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          bottom: 9,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: tkGradientBlue,
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.play_arrow_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  anime.currentEp.isNotEmpty
                      ? anime.currentEp.replaceFirst('EP', 'Episode')
                      : 'New episode',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: tkCoral,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  anime.name.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
