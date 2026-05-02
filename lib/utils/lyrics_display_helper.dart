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
}
