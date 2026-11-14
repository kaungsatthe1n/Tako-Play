import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'tako_pressable_card.dart';

class RecentlyAddedAnimeCard extends StatelessWidget {
  const RecentlyAddedAnimeCard({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: TakoPressableCard(
        onTap: () => Get.toNamed(
          Routes.videoListScreen,
          arguments: {'anime': anime},
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF12121D),
            border: Border.all(color: const Color(0xFF29263F)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x45000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 194,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        anime.imageUrl.isEmpty
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
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x22090A12),
                                Color(0xE8090A12),
                              ],
                              stops: [0, .42, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 9,
                          left: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          bottom: 9,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: tkGradientBlue.withValues(alpha: .94),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x907867F7),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child:
                                const Icon(Icons.play_arrow_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
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
                SizedBox(
                  height: 36,
                  child: Text(
                    anime.name.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
