import 'package:fluent_lyrics/utils/string_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns one for identical strings', () {
    expect(JaroWinklerSimilarity.getJaroWinklerScore('hello', 'hello'), 1.0);
  });

  test('returns zero when either string is empty', () {
    expect(JaroWinklerSimilarity.getJaroWinklerScore('', 'hello'), 0.0);
    expect(JaroWinklerSimilarity.getJaroWinklerScore('hello', ''), 0.0);
  });

  test('returns a higher score for closer matches', () {
    final close = JaroWinklerSimilarity.getJaroWinklerScore(
      'fluent lyrics',
      'fluent lyric',
    );
    final far = JaroWinklerSimilarity.getJaroWinklerScore(
      'fluent lyrics',
      'random text',
    );

    expect(close, greaterThan(far));
  });
}
