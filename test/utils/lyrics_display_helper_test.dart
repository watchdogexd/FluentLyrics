import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/lyrics_display_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Lyric lyric(String text, int seconds) {
    return Lyric(
      startTime: Duration(seconds: seconds),
      endTime: Duration(seconds: seconds + 1),
      text: text,
    );
  }

  test('stripRichSync removes inline parts and preserves line fields', () {
    final richLine = Lyric(
      startTime: const Duration(seconds: 1),
      endTime: const Duration(seconds: 3),
      text: 'hello',
      translation: '你好',
      inlineParts: [
        LyricInlinePart(
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 2),
          text: 'hello',
        ),
      ],
    );

    final stripped = LyricsDisplayHelper.stripRichSync([richLine]);

    expect(stripped, hasLength(1));
    expect(stripped.first.text, 'hello');
    expect(stripped.first.translation, '你好');
    expect(stripped.first.startTime, const Duration(seconds: 1));
    expect(stripped.first.endTime, const Duration(seconds: 3));
    expect(stripped.first.inlineParts, isNull);
  });

  test('stripRichSync keeps plain lyric instances unchanged', () {
    final plainLine = Lyric(
      startTime: const Duration(seconds: 1),
      endTime: const Duration(seconds: 2),
      text: 'plain',
    );

    final stripped = LyricsDisplayHelper.stripRichSync([plainLine]);

    expect(stripped, hasLength(1));
    expect(stripped.first, same(plainLine));
  });

  test('isInterlude returns true only for current empty lyric line', () {
    final lyrics = [lyric('hello', 0), lyric('', 5), lyric('world', 10)];

    expect(LyricsDisplayHelper.isInterlude(lyrics, 1), isTrue);
    expect(LyricsDisplayHelper.isInterlude(lyrics, 0), isFalse);
    expect(LyricsDisplayHelper.isInterlude(lyrics, 3), isFalse);
  });

  test('interludeProgressForPosition applies offsets and clamps progress', () {
    final lyrics = [lyric('', 5), lyric('next', 10)];

    final progress = LyricsDisplayHelper.interludeProgressForPosition(
      lyrics: lyrics,
      currentIndex: 0,
      position: const Duration(seconds: 6),
      globalOffset: const Duration(seconds: 1),
      trackOffset: Duration.zero,
      interludeOffset: const Duration(milliseconds: 500),
    );

    expect(progress, closeTo(0.4444, 0.001));
  });

  test('interludeProgressForPosition returns zero for invalid interlude state', () {
    final lyrics = [lyric('hello', 0), lyric('world', 5)];

    final progress = LyricsDisplayHelper.interludeProgressForPosition(
      lyrics: lyrics,
      currentIndex: 0,
      position: const Duration(seconds: 2),
      globalOffset: Duration.zero,
      trackOffset: Duration.zero,
      interludeOffset: const Duration(milliseconds: 500),
    );

    expect(progress, 0.0);
  });

  test('interludeDuration returns remaining gap minus offset', () {
    final lyrics = [lyric('', 5), lyric('next', 10)];

    final duration = LyricsDisplayHelper.interludeDuration(
      lyrics: lyrics,
      currentIndex: 0,
      interludeOffset: const Duration(milliseconds: 500),
    );

    expect(duration, const Duration(milliseconds: 4500));
  });

  test('buildDisplayedLyrics strips inline parts when rich sync is disabled', () {
    final lyricsResult = LyricsResult(
      lyrics: [
        Lyric(
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 2),
          text: 'hello',
          inlineParts: [
            LyricInlinePart(
              startTime: const Duration(seconds: 1),
              endTime: const Duration(seconds: 1, milliseconds: 500),
              text: 'he',
            ),
          ],
        ),
      ],
      source: 'Musixmatch',
    );

    final displayed = LyricsDisplayHelper.buildDisplayedLyrics(
      lyricsResult: lyricsResult,
      richSyncEnabled: false,
    );

    expect(displayed.first.inlineParts, isNull);
  });

  test('buildDisplayedLyrics preserves inline parts when rich sync is enabled', () {
    final lyricsResult = LyricsResult(
      lyrics: [
        Lyric(
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 2),
          text: 'hello',
          inlineParts: [
            LyricInlinePart(
              startTime: const Duration(seconds: 1),
              endTime: const Duration(seconds: 1, milliseconds: 500),
              text: 'he',
            ),
          ],
        ),
      ],
      source: 'Musixmatch',
    );

    final displayed = LyricsDisplayHelper.buildDisplayedLyrics(
      lyricsResult: lyricsResult,
      richSyncEnabled: true,
    );

    expect(displayed.first.inlineParts, isNotNull);
  });

  test('buildDisplayedLyrics aligns translations onto base lyrics', () {
    final lyricsResult = LyricsResult(
      lyrics: [lyric('hello', 1)],
      source: 'QQ Music',
    );
    final translationResult = LyricsResult(
      lyrics: [],
      source: 'Netease Music',
      translation: true,
      rawTranslation: const [
        {'original': 'hello', 'translated': '你好'},
      ],
    );

    final displayed = LyricsDisplayHelper.buildDisplayedLyrics(
      lyricsResult: lyricsResult,
      richSyncEnabled: false,
      translationEnabled: true,
      translationResult: translationResult,
      translationAlignmentThreshold: 50,
    );

    expect(displayed.first.translation, '你好');
  });
}
