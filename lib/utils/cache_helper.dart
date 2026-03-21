import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CacheHelper {
  static Future<int> getArtworkCacheSize() async {
    try {
      int totalSize = 0;
      final tempDir = await getTemporaryDirectory();
      final tempCacheDir = Directory('${tempDir.path}/libCachedImageData');
      if (tempCacheDir.existsSync()) {
        await for (var file in tempCacheDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      final cacheDir = await getApplicationCacheDirectory();
      final appCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (appCacheDir.existsSync()) {
        await for (var file in appCacheDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error getting artwork cache size: $e');
      return 0;
    }
  }
}
