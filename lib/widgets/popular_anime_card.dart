import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/cache_manager.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

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
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Get.toNamed(
                Routes.videoListScreen,
                arguments: {'anime': anime},
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      anime.imageUrl.isEmpty
                          ? const ColoredBox(color: tkGrey)
                          : CachedNetworkImage(
                              key: ValueKey(anime.imageUrl),
                              cacheManager: CustomCacheManager.instance,
                              fit: BoxFit.cover,
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
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Text(
                            'TRENDING',
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
                          maxLines: 2,
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
