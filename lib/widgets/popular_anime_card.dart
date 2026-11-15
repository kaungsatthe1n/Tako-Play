import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'tako_pressable_card.dart';

class PopularAnimeCard extends StatelessWidget {
  const PopularAnimeCard({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final metadata =
        anime.genres.take(2).map((genre) => genre.name).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: SizedBox(
        width: 132,
        child: Material(
          color: Colors.transparent,
          child: TakoPressableCard(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Get.toNamed(
              Routes.videoListScreen,
              arguments: {'anime': anime},
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox.expand(
                      child: anime.imageUrl.isEmpty
                          ? const ColoredBox(color: tkGrey)
                          : CachedNetworkImage(
                              key: ValueKey(anime.imageUrl),
                              cacheManager: CustomCacheManager.instance,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              imageUrl: anime.imageUrl,
                              errorWidget: (_, __, ___) =>
                                  const ColoredBox(color: tkGrey),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  anime.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metadata.isNotEmpty
                      ? metadata
                      : (anime.currentEp.isNotEmpty
                          ? anime.currentEp
                          : 'Anime'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: tkMutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
