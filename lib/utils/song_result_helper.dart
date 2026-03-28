import 'string_similarity.dart';

class SongResultHelper {
  static List<ProcessedSong> orderBySimilarity(
    List<GenericSong> songs,
    String queryTitle,
    List<String> queryArtist,
    int queryDurationMs,
    int durationToleranceMs,
  ) {
    final List<ProcessedSong> processedSongs = [];
    for (var song in songs) {
      final titleSimilarity = JaroWinklerSimilarity.getJaroWinklerScore(
        queryTitle.toLowerCase(),
        song.title.toLowerCase(),
      );

      double artistSimilarity = 0;
      if (queryArtist.length > 1) {
        final artistSimilarities = queryArtist.map((name) {
          // calc thru all artistNames and return the max one
          return song.artist
              .map((resultName) {
                return JaroWinklerSimilarity.getJaroWinklerScore(
                  name.toLowerCase(),
                  resultName.toLowerCase(),
                );
              })
              .reduce((a, b) => a > b ? a : b);
        });
        // take the average of all artist similarities
        artistSimilarity =
            artistSimilarities.reduce((a, b) => a + b) /
            artistSimilarities.length;
      } else {
        artistSimilarity = JaroWinklerSimilarity.getJaroWinklerScore(
          queryArtist.join(', ').toLowerCase(), // it essentially same as .first
          song.artist.join(', ').toLowerCase(),
        );
      }

      if (titleSimilarity < 0.7 || artistSimilarity < 0.5) {
        // print(
        //   'titleSimilarity: $titleSimilarity (${queryTitle.toLowerCase()} vs ${song.title.toLowerCase()})',
        // );
        // print(
        //   'artistSimilarity: $artistSimilarity (${queryArtist.join(', ').toLowerCase()} vs ${song.artist.join(', ').toLowerCase()})',
        // );
        continue;
      }
      // filter songs that are too different in duration
      if ((song.durationMs - queryDurationMs).abs() > durationToleranceMs) {
        // print(
        //   'durationSimilarity: ${(song.durationMs - queryDurationMs).abs()} > $durationToleranceMs',
        // );
        continue;
      }

      processedSongs.add(
        ProcessedSong(
          data: song.data,
          title: song.title,
          artist: song.artist,
          durationMs: song.durationMs,
          titleSimilarity: titleSimilarity,
          artistSimilarity: artistSimilarity,
        ),
      );
    }
    processedSongs.sort((a, b) => b.similarity.compareTo(a.similarity));
    return processedSongs;
  }
}

class GenericSong {
  final String title;
  final List<String> artist;
  final int durationMs;
  final Map<String, dynamic> data;

  GenericSong({
    required this.data,
    required this.title,
    required this.artist,
    required this.durationMs,
  });
}

class ProcessedSong extends GenericSong {
  final double titleSimilarity;
  final double artistSimilarity;

  ProcessedSong({
    required super.data,
    required super.title,
    required super.artist,
    required super.durationMs,
    required this.titleSimilarity,
    required this.artistSimilarity,
  });

  double get similarity {
    return titleSimilarity * 0.6 + artistSimilarity * 0.4;
  }
}
