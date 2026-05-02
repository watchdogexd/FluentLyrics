import '../models/lyric_model.dart';

LyricsResult? selectBetterCandidate(
  LyricsResult candidate,
  LyricsResult? best,
  bool richSyncEnabled,
) {
  if (best == null) {
    return candidate.copyWith(
      lyrics: candidate.lyrics,
      source: candidate.source,
      isSynced: candidate.isSynced,
      writtenBy: candidate.writtenBy,
      composer: candidate.composer,
      contributor: candidate.contributor,
      copyright: candidate.copyright,
      isPureMusic: candidate.isPureMusic,
      artworkUrls: candidate.artworkUrls,
    );
  }

  final bool candidateIsBetter;
  if (candidate.isPureMusic && !best.isPureMusic) {
    candidateIsBetter = false;
  } else if (candidate.lyrics.isNotEmpty && best.lyrics.isEmpty) {
    candidateIsBetter = true;
  } else if (candidate.lyrics.isNotEmpty &&
      candidate.isRichSync &&
      richSyncEnabled &&
      !best.isRichSync) {
    candidateIsBetter = true;
  } else if (candidate.lyrics.isNotEmpty &&
      candidate.isSynced &&
      !best.isSynced) {
    candidateIsBetter = true;
  } else if ((candidate.artworkUrls?.length ?? 0) >
      (best.artworkUrls?.length ?? 0)) {
    candidateIsBetter = true;
  } else {
    candidateIsBetter = false;
  }

  if (!candidateIsBetter) {
    return best;
  }

  return candidate.copyWith(
    lyrics: candidate.lyrics,
    source: candidate.source,
    isSynced: candidate.isSynced,
    writtenBy: candidate.writtenBy,
    composer: candidate.composer,
    contributor: candidate.contributor,
    copyright: candidate.copyright,
    isPureMusic: candidate.isPureMusic,
    artworkUrls: candidate.artworkUrls,
  );
}
