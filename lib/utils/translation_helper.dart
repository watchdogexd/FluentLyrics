import '../models/lyric_model.dart';

class TranslationHelper {
  static List<Map<String, String>> pairTranslations({
    required List<Lyric> originalLyrics,
    required List<Lyric> translatedLyrics,
    int translationBias = 0,
  }) {
    final List<Map<String, String>> rawTranslation = [];
    // Try to pair with original lyrics based on timestamps

    for (var transLine in translatedLyrics) {
      // Find matching original line
      Lyric? bestMatch;

      // 1. Try perfect match first
      for (var l in originalLyrics) {
        if (l.startTime.inMilliseconds == transLine.startTime.inMilliseconds) {
          bestMatch = l;
          break;
        }
      }

      // 2. If no perfect match, find closest within tolerance, if strict mode is not enabled (!=0)
      if (bestMatch == null && translationBias != 0) {
        // Use bias magnitude as tolerance window
        final int tolerance = translationBias.abs();
        int minDiff = tolerance;

        for (var l in originalLyrics) {
          final diff =
              (l.startTime.inMilliseconds - transLine.startTime.inMilliseconds)
                  .abs();
          if (diff < minDiff) {
            minDiff = diff.toInt();
            bestMatch = l;
          }
        }
      }

      if (bestMatch != null && bestMatch.text.isNotEmpty) {
        rawTranslation.add({
          'original': bestMatch.text,
          'translated': transLine.text,
        });
      }
    }

    return rawTranslation;
  }
}
