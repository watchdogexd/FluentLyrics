import 'package:isar/isar.dart';
import 'lyric_model.dart';

part 'translation_cache.g.dart';

@Collection()
class TranslationCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheId;

  late String source;
  late String language;
  late String originalContentDigest; // To verify if it matches current lyrics
  late List<TranslationItem> lyrics;

  LyricsResult toLyricsResult() {
    return LyricsResult(
      lyrics: lyrics
          .map(
            (l) => Lyric(
              startTime: Duration(milliseconds: l.startTimeMs),
              endTime: l.endTimeMs != null
                  ? Duration(milliseconds: l.endTimeMs!)
                  : null,
              text: l.text,
            ),
          )
          .toList(),
      source: source,
      language: language,
      translation: true,
      translationProvider: source,
    );
  }

  static TranslationCache fromLyricsResult(
    String cacheId,
    String contentDigest,
    LyricsResult result,
  ) {
    return TranslationCache()
      ..cacheId = cacheId
      ..source = result.source
      ..language = result.language ?? 'en'
      ..originalContentDigest = contentDigest
      ..lyrics = result.lyrics
          .map(
            (l) => TranslationItem()
              ..startTimeMs = l.startTime.inMilliseconds
              ..endTimeMs = l.endTime?.inMilliseconds
              ..text = l.text,
          )
          .toList();
  }
}

@embedded
class TranslationItem {
  late int startTimeMs;
  int? endTimeMs;
  late String text;
}
