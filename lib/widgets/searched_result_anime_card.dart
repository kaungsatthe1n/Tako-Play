import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'cache_image_with_cachemanager.dart';

class SearchedResultAnimeCard extends StatelessWidget {
  const SearchedResultAnimeCard({
    super.key,
    required this.anime,
    this.heroTag,
    this.enableHero = true,
    this.fallbackCategoryLabel = 'Anime',
  });

  final Anime anime;
  final String? heroTag;
  final bool enableHero;
  final String fallbackCategoryLabel;

  @override
  Widget build(BuildContext context) {
    final isDub = anime.name.toString().toLowerCase().contains('dub');
    return GestureDetector(
      onTap: () =>
          Get.toNamed(Routes.videoListScreen, arguments: {'anime': anime}),
      child: enableHero
          ? Hero(
              tag: heroTag ?? anime.id.toString(),
              child: _buildCardContents(isDub),
            )
          : _buildCardContents(isDub),
    );
  }

  Widget _buildCardContents(bool isDub) => Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageWithCacheManager(
                      imageUrl: anime.imageUrl.toString(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB0090A12)],
                          stops: [.48, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDub ? Colors.orange : tkGradientBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDub ? 'DUB' : 'SUB',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              anime.name.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              anime.releasedDate.isNotEmpty
                  ? anime.releasedDate
                  : fallbackCategoryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: tkMutedText, fontSize: 11),
            ),
          ],
        ),
      );
}
