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
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 156,
        child: Hero(
          tag: anime.id.toString(),
          child: Material(
            color: Colors.transparent,
            child: TakoPressableCard(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Get.toNamed(
                Routes.videoListScreen,
                arguments: {'anime': anime},
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: tkDarkBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF383E68)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52000000),
                      blurRadius: 16,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
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
                            colors: [Colors.transparent, Color(0xE0090A12)],
                            stops: [.38, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tkCoral,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        left: 12,
                        child: Text(
                          anime.name.toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
