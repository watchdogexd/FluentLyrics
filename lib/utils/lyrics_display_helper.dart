import '../models/lyric_model.dart';

class LyricsDisplayHelper {
  const LyricsDisplayHelper._();

  static List<Lyric> stripRichSync(List<Lyric> source) {
    return source.map((lyric) {
      if (lyric.inlineParts != null && lyric.inlineParts!.isNotEmpty) {
        return Lyric(
          startTime: lyric.startTime,
          endTime: lyric.endTime,
          text: lyric.text,
          inlineParts: null,
          translation: lyric.translation,
        );
      }
      return lyric;
    }).toList();
  }

  static bool isInterlude(List<Lyric> lyrics, int currentIndex) {
    if (lyrics.isEmpty) return false;
    if (currentIndex < 0 || currentIndex >= lyrics.length) return false;
    return lyrics[currentIndex].text.trim().isEmpty;
  }

  static double interludeProgressForPosition({
    required List<Lyric> lyrics,
    required int currentIndex,
    required Duration position,
    required Duration globalOffset,
    required Duration trackOffset,
    required Duration interludeOffset,
  }) {
    if (!isInterlude(lyrics, currentIndex)) return 0.0;
    if (currentIndex >= lyrics.length - 1) return 0.0;

    final adjustedPosition = position + globalOffset + trackOffset;
    final currentStartTime = lyrics[currentIndex].startTime;
    final nextStartTime = lyrics[currentIndex + 1].startTime;
    final duration =
        nextStartTime.inMilliseconds -
        currentStartTime.inMilliseconds -
        interludeOffset.inMilliseconds;

    if (duration <= 0) return 0.0;

    return ((adjustedPosition.inMilliseconds - currentStartTime.inMilliseconds) /
            duration)
        .clamp(0.0, 1.0);
  }

  static Duration interludeDuration({
    required List<Lyric> lyrics,
    required int currentIndex,
    required Duration interludeOffset,
  }) {
    if (!isInterlude(lyrics, currentIndex)) return Duration.zero;
    if (currentIndex >= lyrics.length - 1) return Duration.zero;

    final currentStartTime = lyrics[currentIndex].startTime;
    final nextStartTime = lyrics[currentIndex + 1].startTime;
    return nextStartTime - currentStartTime - interludeOffset;
  }
}
