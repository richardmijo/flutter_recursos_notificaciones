import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for images with sensible defaults for demo purposes.
/// Configure `maxNrOfCacheObjects` and `maxAgeCacheObject` according to your app needs.
class CustomCacheManager {
  static const key = 'customImageCache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // files older than this are removed
      maxNrOfCacheObjects: 100, // keep up to 100 files
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
