import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../helpers/cache_manager.dart';

class NetworkImageWithCacheManager extends StatelessWidget {
  const NetworkImageWithCacheManager({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      cacheManager: CustomCacheManager.instance,
      errorWidget: (context, _, widget) {
        return const Icon(Icons.error_sharp);
      },
      imageUrl: imageUrl,
      fit: BoxFit.cover,
    );
  }
}
