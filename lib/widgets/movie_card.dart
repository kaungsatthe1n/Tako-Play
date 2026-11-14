import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'tako_pressable_card.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return TakoPressableCard(
      onTap: () =>
          Get.toNamed(Routes.videoListScreen, arguments: {'anime': anime}),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 142,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF12121D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF29263F)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(11)),
              child: SizedBox(
                width: 96,
                height: 142,
                child: anime.imageUrl.isEmpty
                    ? const ColoredBox(
                        color: tkGrey,
                        child:
                            Icon(Icons.movie_outlined, color: Colors.white54),
                      )
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MOVIE',
                      style: TextStyle(
                        color: tkMutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        anime.name.toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Watch',
                          style: TextStyle(
                            color: tkGradientBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: tkGradientBlue, size: 15),
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
