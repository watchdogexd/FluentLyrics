import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/lyrics_display_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
