import 'package:isar/isar.dart';
import 'lyric_model.dart';

part 'lyric_cache.g.dart';

@Collection()
class LyricCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheId;

  late String source;
  late bool isSynced;
  late bool isRichSync;
  String? writtenBy;
  String? composer;
  String? contributor;
  String? copyright;
  String? artworkUrl;
  late bool isPureMusic;
  SubLyricsItem? subLyrics;

  late List<LyricItem> lyrics;

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
              inlineParts: l.inlineParts
                  ?.map(
                    (p) => LyricInlinePart(
                      startTime: Duration(milliseconds: p.startTimeMs),
                      endTime: Duration(milliseconds: p.endTimeMs),
                      text: p.text,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      source: source,
      isSynced: isSynced,
      isRichSync: isRichSync,
      writtenBy: writtenBy,
      composer: composer,
      contributor: contributor,
      copyright: copyright,
      artworkUrl: artworkUrl,
      isPureMusic: isPureMusic,
      subLyrics: subLyrics?.toLyricsResult(),
    );
  }

  static LyricCache fromLyricsResult(String cacheId, LyricsResult result) {
    final cache = LyricCache();
    cache.cacheId = cacheId;
    cache.source = result.source;
    cache.isSynced = result.isSynced;
    cache.isRichSync = result.isRichSync;
    cache.writtenBy = result.writtenBy;
    cache.composer = result.composer;
    cache.contributor = result.contributor;
    cache.copyright = result.copyright;
    cache.artworkUrl = result.artworkUrl;
    cache.isPureMusic = result.isPureMusic;
    cache.lyrics = result.lyrics
        .map(
          (l) => LyricItem()
            ..startTimeMs = l.startTime.inMilliseconds
            ..endTimeMs = l.endTime?.inMilliseconds
            ..text = l.text
            ..inlineParts = l.inlineParts
                ?.map(
                  (p) => LyricItemInlinePart()
                    ..startTimeMs = p.startTime.inMilliseconds
                    ..endTimeMs = p.endTime.inMilliseconds
                    ..text = p.text,
                )
                .toList(),
        )
        .toList();
    if (result.subLyrics != null) {
      cache.subLyrics = SubLyricsItem.fromLyricsResult(result.subLyrics!);
    }
    return cache;
  }
}

@embedded
class SubLyricsItem {
  String? source;
  String? language;
  String? translationProvider;
  String? translationContributor;
  List<RawTranslationPair>? rawTranslation;

  LyricsResult toLyricsResult() {
    return LyricsResult(
      lyrics: [],
      source: source ?? '',
      language: language,
      translation: true,
      translationProvider: translationProvider,
      translationContributor: translationContributor,
      rawTranslation:
          rawTranslation
              ?.map(
                (e) => {
                  'original': e.original ?? '',
                  'translated': e.translated ?? '',
                },
              )
              .toList(),
    );
  }

  static SubLyricsItem fromLyricsResult(LyricsResult result) {
    final item = SubLyricsItem();
    item.source = result.source;
    item.language = result.language;
    item.translationProvider = result.translationProvider;
    item.translationContributor = result.translationContributor;
    item.rawTranslation =
        result.rawTranslation
            ?.map(
              (e) =>
                  RawTranslationPair()
                    ..original = e['original']
                    ..translated = e['translated'],
            )
            .toList();
    return item;
  }
}

@embedded
class RawTranslationPair {
  String? original;
  String? translated;
}

@embedded
class LyricItem {
  late int startTimeMs;
  int? endTimeMs;
  late String text;
  List<LyricItemInlinePart>? inlineParts;
}

@embedded
class LyricItemInlinePart {
  late int startTimeMs;
  late int endTimeMs;
  late String text;
}
