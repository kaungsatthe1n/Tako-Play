import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'cache_image_with_cachemanager.dart';

class RecentAnimeCard extends StatelessWidget {
  const RecentAnimeCard({
    super.key,
    required this.currentEp,
    required this.epUrl,
    required this.name,
    required this.imageUrl,
    required this.id,
  });

  final String id;
  final String name;
  final String currentEp;
  final String imageUrl;
  final String epUrl;

  void _continueWatching() {
    final path = Uri.tryParse(epUrl)?.path ?? epUrl;
    if (path.startsWith('/category/') || path.startsWith('/anime/')) {
      Get.toNamed(
        Routes.videoListScreen,
        arguments: {
          'anime': Anime(
            id: id,
            name: name,
            imageUrl: imageUrl,
            animeUrl: epUrl,
          ),
        },
      );
      return;
    }
    Get.toNamed(Routes.mediaFetchScreen, arguments: {'animeUrl': epUrl});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _continueWatching,
        child: Ink(
          height: 118,
          decoration: BoxDecoration(
            color: tkDarkBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
                child: SizedBox(
                  width: 84,
                  height: double.infinity,
                  child: NetworkImageWithCacheManager(imageUrl: imageUrl),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 15, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentEp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tkCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      const Text('Continue watching',
                          style: TextStyle(color: tkMutedText, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 13),
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: tkGradientBlue),
                  onPressed: _continueWatching,
                  icon: const Icon(Icons.play_arrow_rounded, size: 21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
