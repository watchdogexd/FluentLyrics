import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/lyric_model.dart';
import '../../models/lyric_cache.dart';
import '../../models/translation_cache.dart';

class LyricsCacheService {
  static Isar? _isar;

  Future<Isar> get _db async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationSupportDirectory();
    _isar ??=
        Isar.getInstance() ??
        await Isar.open(
          [LyricCacheSchema, TranslationCacheSchema],
          directory: dir.path,
          name: 'lyrics_cache',
        );
    return _isar!;
  }

  String generateCacheId(
    String title,
    String artist,
    String? album,
    int durationSeconds, {
    bool isRichSync = false,
  }) {
    final input = '$title|$artist|${album ?? ''}|$durationSeconds';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}_${isRichSync ? 'rich' : 'std'}';
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String? album,
    required int durationSeconds,
  }) async {
    // Try rich sync first
    final richCacheId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: true,
    );
    final richCached = await getCachedLyrics(richCacheId);
    if (richCached != null && richCached.lyrics.isNotEmpty) {
      return richCached.copyWith(source: '${richCached.source} (cached)');
    }

    // Fallback to standard sync
    final stdCacheId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: false,
    );
    final stdCached = await getCachedLyrics(stdCacheId);
    if (stdCached != null && stdCached.lyrics.isNotEmpty) {
      return stdCached.copyWith(source: '${stdCached.source} (cached)');
    }

    return LyricsResult.empty();
  }

  Future<LyricsResult?> getCachedLyrics(String cacheId) async {
    final isar = await _db;
    final cached = await isar.lyricCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findFirst();
    if (cached == null) return null;

    try {
      return cached.toLyricsResult();
    } catch (e) {
      await clearCache(cacheId);
      return null;
    }
  }

  Future<void> cacheLyrics(
    String title,
    String artist,
    String? album,
    int durationSeconds,
    LyricsResult result,
  ) async {
    final cacheId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: result.isRichSync,
    );
    final isar = await _db;
    final cache = LyricCache.fromLyricsResult(cacheId, result);
    await isar.writeTxn(() async {
      await isar.lyricCaches.put(cache);
    });
  }

  Future<void> clearCache(String cacheId) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches.filter().cacheIdEqualTo(cacheId).deleteAll();
    });
  }

  Future<void> clearTrackCache(
    String title,
    String artist,
    String? album,
    int durationSeconds,
  ) async {
    final richId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: true,
    );
    final stdId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: false,
    );
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches
          .filter()
          .cacheIdEqualTo(richId)
          .or()
          .cacheIdEqualTo(stdId)
          .deleteAll();
    });
  }

  Future<void> clearAllCache() async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches.clear();
      await isar.translationCaches.clear();
    });
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final isar = await _db;
    final count = await isar.lyricCaches.count();
    final size = await isar.getSize();
    return {'count': count, 'size': size};
  }

  // Translation Caching
  Future<LyricsResult?> getCachedTranslation(
    String cacheId,
    String contentDigest,
  ) async {
    final isar = await _db;
    final cached = await isar.translationCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findFirst();

    if (cached == null) return null;

    // Check if original content digest matches
    if (cached.originalContentDigest != contentDigest) {
      // Content changed, translation might be invalid
      await isar.writeTxn(() async {
        await isar.translationCaches
            .filter()
            .cacheIdEqualTo(cacheId)
            .deleteAll();
      });
      return null;
    }

    try {
      return cached.toLyricsResult();
    } catch (e) {
      await isar.writeTxn(() async {
        await isar.translationCaches
            .filter()
            .cacheIdEqualTo(cacheId)
            .deleteAll();
      });
      return null;
    }
  }

  Future<void> cacheTranslation(
    String cacheId,
    String contentDigest,
    LyricsResult result,
  ) async {
    final isar = await _db;
    final cache = TranslationCache.fromLyricsResult(
      cacheId,
      contentDigest,
      result,
    );
    await isar.writeTxn(() async {
      await isar.translationCaches.put(cache);
    });
  }

  Future<void> clearTranslationCache(String cacheId) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.translationCaches.filter().cacheIdEqualTo(cacheId).deleteAll();
    });
  }

  String generateTranslationCacheId(
    String title,
    String artist,
    String language,
  ) {
    final input = '$title|$artist|$language';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String generateContentDigest(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
