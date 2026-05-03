import '../models/lyric_model.dart';

bool matchesTranslationTargetLanguage(
  List<String> targetLanguages,
  String language,
) {
  final lowercaseLanguage = language.toLowerCase();
  for (final target in targetLanguages) {
    if (target.toLowerCase() == lowercaseLanguage) {
      return true;
    }
  }
  return false;
}

List<LyricsResult> appendTranslationCandidateIfNeeded(
  List<LyricsResult> candidates,
  LyricsResult candidate,
) {
  final isDuplicate = candidates.any(
    (existing) =>
        existing.translationProvider == candidate.translationProvider &&
        existing.language == candidate.language,
  );
  if (isDuplicate) return candidates;
  return List.unmodifiable([...candidates, candidate]);
}

List<LyricsResult> appendCandidateIfNeeded(
  List<LyricsResult> candidates,
  LyricsResult candidate,
) {
  final isDuplicate = candidates.any(
    (existing) =>
        existing.source == candidate.source &&
        existing.isSynced == candidate.isSynced &&
        existing.isRichSync == candidate.isRichSync,
  );
  if (isDuplicate) return candidates;
  return List.unmodifiable([...candidates, candidate]);
}

LyricsResult prepareLyricsResultForDisplay(LyricsResult result) {
  var prepared = result.trim();
  if (prepared.lyrics.isNotEmpty &&
      prepared.lyrics[0].startTime > const Duration(seconds: 3)) {
    final newLyrics = List<Lyric>.from(prepared.lyrics)
      ..insert(
        0,
        Lyric(
          text: '',
          startTime: Duration.zero,
          endTime: prepared.lyrics[0].startTime,
        ),
      );
    prepared = prepared.copyWith(lyrics: newLyrics);
  }
  return prepared;
}
