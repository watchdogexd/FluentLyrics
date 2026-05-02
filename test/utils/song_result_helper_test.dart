import 'package:fluent_lyrics/utils/song_result_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GenericSong song({
    required String title,
    required List<String> artist,
    required int durationMs,
  }) {
    return GenericSong(
      data: {'title': title},
      title: title,
      artist: artist,
      durationMs: durationMs,
    );
  }

  test('orders best similarity match first', () {
    final songs = [
      song(title: 'Another Song', artist: ['Someone Else'], durationMs: 100000),
      song(title: 'Fluent Lyrics', artist: ['Koto'], durationMs: 200000),
    ];

    final ordered = SongResultHelper.orderBySimilarity(
      songs,
      'Fluent Lyrics',
      ['Koto'],
      200000,
      5000,
    );

    expect(ordered, hasLength(1));
    expect(ordered.first.title, 'Fluent Lyrics');
  });

  test('filters songs outside duration tolerance', () {
    final songs = [
      song(title: 'Fluent Lyrics', artist: ['Koto'], durationMs: 220000),
    ];

    final ordered = SongResultHelper.orderBySimilarity(
      songs,
      'Fluent Lyrics',
      ['Koto'],
      200000,
      5000,
    );

    expect(ordered, isEmpty);
  });

  test('uses average artist similarity for multi-artist queries', () {
    final songs = [
      song(title: 'Duet Song', artist: ['Alice', 'Bob'], durationMs: 180000),
    ];

    final ordered = SongResultHelper.orderBySimilarity(
      songs,
      'Duet Song',
      ['Alice', 'Bob'],
      180000,
      5000,
    );

    expect(ordered, hasLength(1));
    expect(ordered.first.artistSimilarity, greaterThanOrEqualTo(0.5));
  });
}
