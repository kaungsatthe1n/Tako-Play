import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// [CustomCacheManager] represents a custom caching mechanism suitable for the
/// needs of the actual app.
class CustomCacheManager {
  static const key = 'customCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 120,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
