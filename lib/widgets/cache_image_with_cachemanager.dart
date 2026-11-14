import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../helpers/cache_manager.dart';
import '../utils/constants.dart';

class NetworkImageWithCacheManager extends StatelessWidget {
  const NetworkImageWithCacheManager({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const ColoredBox(color: tkGrey);
    }
    final displayUrl = imageUrl.replaceFirst(
      RegExp(r'/poster-sm/w_\d+/h_\d+/'),
      '/poster/w_360/h_480/',
    );
    return CachedNetworkImage(
      cacheManager: CustomCacheManager.instance,
      errorWidget: (context, _, widget) {
        return const Icon(Icons.error_sharp);
      },
      imageUrl: displayUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
  }
}
