import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../models/lyric_model.dart';

class LyricAligner {
  static List<Lyric> align({
    required List<Lyric> originalLyrics,
    required List<Map<String, String>> rawTranslation,
    int similarityThreshold = 80,
  }) {
    if (originalLyrics.isEmpty || rawTranslation.isEmpty) {
      return originalLyrics;
    }

    final List<Lyric> newLyrics = [];
    int nextSearchStartIndex = 0;

    for (var line in originalLyrics) {
      bool matched = false;
      for (int i = nextSearchStartIndex; i < rawTranslation.length; i++) {
        final originalText = rawTranslation[i]['original'] ?? '';
        final translatedText = rawTranslation[i]['translated'] ?? '';

        if (_calcLineSimilarity(line.text, originalText) > similarityThreshold) {
          newLyrics.add(
            Lyric(
              startTime: line.startTime,
              endTime: line.endTime,
              text: line.text,
              inlineParts: line.inlineParts,
              translation: translatedText,
            ),
          );
          nextSearchStartIndex = i + 1;
          matched = true;
          break;
        }
      }

      if (!matched) {
        newLyrics.add(line);
      }
    }

    return newLyrics;
  }

  static int _calcLineSimilarity(String line1, String line2) {
    if (line1.isEmpty || line2.isEmpty) return 0;
    
    // 1. Simple normalization
    String clean1 = line1.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    String clean2 = line2.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

    if (clean1.isEmpty || clean2.isEmpty) return 0;

    // 2. Calculate similarity (0-100)
    try {
      return ratio(clean1, clean2);
    } catch (e) {
      debugPrint('[LyricAligner] Error calculating similarity: $e');
      return 0;
    }
  }
}
