import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CacheHelper {
  static Future<Map<String, int>> getArtworkCacheStats() async {
    try {
      int totalSize = 0;
      int count = 0;
      final cacheDir = await getApplicationCacheDirectory();
      final appCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (appCacheDir.existsSync()) {
        await for (var file in appCacheDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalSize += await file.length();
            count++;
          }
        }
      }

      return {'count': count, 'size': totalSize};
    } catch (e) {
      debugPrint('Error getting artwork cache stats: $e');
      return {'count': 0, 'size': 0};
    }
  }
}
