import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Dedicated on-disk cache for instruction videos.
///
/// Videos are stored under a stable key (the video's slug/id) so a replay
/// reads from disk instead of re-downloading. A long stale period keeps the
/// instruction clips around, while a small object cap bounds disk use.
class VideoCacheManager {
  static const key = 'instructionVideoCache';

  static final CacheManager instance = CacheManager(
    Config(key, stalePeriod: const Duration(days: 90), maxNrOfCacheObjects: 30),
  );
}
