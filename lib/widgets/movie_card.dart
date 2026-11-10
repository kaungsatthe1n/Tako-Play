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
      borderRadius: BorderRadius.circular(14),
      enableInkFeedback: false,
      child: Container(
        height: 142,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF252B4B), tkDarkBlue],
          ),
          border: Border.all(color: const Color(0xFF373E67)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42000000),
              blurRadius: 13,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(13)),
              child: SizedBox(
                width: 108,
                height: 142,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    anime.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            key: ValueKey(anime.imageUrl),
                            cacheManager: CustomCacheManager.instance,
                            fit: BoxFit.cover,
                            imageUrl: anime.imageUrl,
                            errorWidget: (_, __, ___) =>
                                const ColoredBox(color: tkGrey),
                          )
                        : const ColoredBox(
                            color: tkGrey,
                            child: Icon(Icons.movie_outlined,
                                color: Colors.white54),
                          ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xBD090A12)],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .48),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 21),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 13, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tkCoral.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_creation_outlined,
                              color: tkCoral, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'FEATURE FILM',
                            style: TextStyle(
                              color: tkCoral,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime.name.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: tkGradientBlue.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x507867F7),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 17),
                          SizedBox(width: 6),
                          Text(
                            'Play movie',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
