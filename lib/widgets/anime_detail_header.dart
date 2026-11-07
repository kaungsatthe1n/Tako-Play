import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'cache_image_with_cachemanager.dart';

class AnimeDetailHeader extends StatelessWidget {
  const AnimeDetailHeader({
    super.key,
    required this.anime,
    required this.imageUrl,
    required this.name,
  });

  final Anime anime;
  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final genres = anime.genres;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NetworkImageWithCacheManager(imageUrl: imageUrl),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: tkCoral.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    anime.status.isNotEmpty ? anime.status : 'ANIME',
                    style: const TextStyle(
                      color: tkCoral,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 21,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  anime.releasedDate.isNotEmpty
                      ? 'Released ${anime.releasedDate}'
                      : 'Now streaming',
                  style: const TextStyle(color: tkMutedText, fontSize: 12),
                ),
                const Spacer(),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: genres.take(3).map((genre) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () =>
                          Get.toNamed(Routes.genreScreen, arguments: genre),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tkDarkBlue,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          genre.name,
                          style:
                              const TextStyle(fontSize: 10, color: tkMutedText),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
