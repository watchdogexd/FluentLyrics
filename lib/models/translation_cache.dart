import 'package:isar/isar.dart';
import 'lyric_model.dart';

part 'translation_cache.g.dart';

@Collection()
class TranslationCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheId;

  late String source;
  late String translationProvider;
  late String? translationContributor;
  late String language;
  late List<TranslationItem> lyrics;
  late List<RawTranslationPair>? rawTranslation;

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
      rawTranslation: rawTranslation
          ?.map((e) => {'original': e.original ?? '', 'translated': e.translated ?? ''})
          .toList(),
      source: source,
      language: language,
      translation: true,
      translationProvider: translationProvider,
      translationContributor: translationContributor,
    );
  }

  static TranslationCache fromLyricsResult(
    String cacheId,
    LyricsResult result,
  ) {
    return TranslationCache()
      ..cacheId = cacheId
      ..source = result.source
      ..translationProvider = result.translationProvider ?? 'unknown'
      ..translationContributor = result.translationContributor ?? 'unknown'
      ..language = result.language ?? 'en'
      ..lyrics = result.lyrics
          .map(
            (l) => TranslationItem()
              ..startTimeMs = l.startTime.inMilliseconds
              ..endTimeMs = l.endTime?.inMilliseconds
              ..text = l.text,
          )
          .toList()
      ..rawTranslation = result.rawTranslation
          ?.map(
            (e) => RawTranslationPair()
              ..original = e['original']
              ..translated = e['translated'],
          )
          .toList();
  }
}

@embedded
class RawTranslationPair {
  String? original;
  String? translated;
}

@embedded
class TranslationItem {
  late int startTimeMs;
  int? endTimeMs;
  late String text;
}
