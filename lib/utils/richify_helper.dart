import 'package:flutter/foundation.dart';
import 'package:string_similarity/string_similarity.dart';
import '../models/lyric_model.dart';

/// Merges word-level timing (inlineParts) from a rich-synced source into a
/// regular synced target, producing a new rich-synced result.
///
/// **Strategy (per target line):**
/// 1. Exact timestamp match against any source line.
/// 2. Text-similarity match (threshold configurable, default 70 %).
/// 3. No match → line kept as-is (no inlineParts).
///
/// The merged result keeps the target's line timestamps and text verbatim;
/// only the `inlineParts` field is borrowed from the source.  The borrowed
/// parts are re-anchored to the target line's start time so playback stays
/// correct even when the two sources have slightly different offsets.
class RichifyHelper {
  /// Similarity threshold (0–100) below which a text match is rejected.
  static const int _kDefaultTextThreshold = 70;

  /// Millisecond window for "close-enough" timestamp matching when no exact
  /// match is found.
  static const int _kTimestampToleranceMs = 300;

  /// Applies rich-sync from [richSource] to [syncedTarget].
  ///
  /// Returns a new [LyricsResult] that:
  /// - Keeps every line from [syncedTarget] (same timestamps, same text).
  /// - Copies [LyricInlinePart]s from the best-matching [richSource] line when
  ///   a confident match is found.
  /// - Has [LyricsResult.isRichSync] == `true` (it will be detected
  ///   automatically by [LyricsResult._checkIfRichSynced]).
  ///
  /// [textThreshold] controls the minimum Dice similarity (0–100) required for
  /// a text-based fallback match.
  static LyricsResult apply({
    required LyricsResult syncedTarget,
    required LyricsResult richSource,
    int textThreshold = _kDefaultTextThreshold,
  }) {
    final sourceLines = richSource.lyrics;

    final newLyrics = syncedTarget.lyrics.map((targetLine) {
      if (targetLine.text.trim().isEmpty) return targetLine;

      // 1. Exact timestamp match.
      final exactMatch = _findByTimestamp(targetLine, sourceLines, 0);
      if (exactMatch != null && (exactMatch.inlineParts?.isNotEmpty ?? false)) {
        return _mergeInlineParts(targetLine, exactMatch);
      }

      // 2. Nearest-timestamp match within tolerance.
      final nearMatch = _findByTimestamp(
        targetLine,
        sourceLines,
        _kTimestampToleranceMs,
      );
      if (nearMatch != null && (nearMatch.inlineParts?.isNotEmpty ?? false)) {
        // Only accept if texts are also similar enough.
        final sim = _similarity(targetLine.text, nearMatch.text);
        if (sim >= textThreshold) {
          return _mergeInlineParts(targetLine, nearMatch);
        }
      }

      // 3. Text-similarity fallback (scan all source lines).
      Lyric? bestText;
      int bestSim = textThreshold - 1;
      for (final src in sourceLines) {
        if (src.inlineParts == null || src.inlineParts!.isEmpty) continue;
        final s = _similarity(targetLine.text, src.text);
        if (s > bestSim) {
          bestSim = s;
          bestText = src;
        }
      }
      if (bestText != null) {
        return _mergeInlineParts(targetLine, bestText);
      }

      return targetLine; // No match — keep plain.
    }).toList();

    final richCount = newLyrics
        .where((l) => l.inlineParts != null && l.inlineParts!.isNotEmpty)
        .length;
    final totalContent = newLyrics
        .where((l) => l.text.trim().isNotEmpty)
        .length;

    debugPrint(
      '[RichifyHelper] Richified $richCount / $totalContent lines '
      '(source: ${richSource.source}, target: ${syncedTarget.source})',
    );

    return syncedTarget.copyWith(
      lyrics: newLyrics,
      isRichSync: true,
      source: '${syncedTarget.source} ✨ Richified',
    );
  }

  /// Returns the coverage fraction (0.0–1.0) of how well [richSource] can
  /// enrich [syncedTarget].  Used by the UI to show a quality indicator before
  /// the user commits.
  static double coverage({
    required LyricsResult syncedTarget,
    required LyricsResult richSource,
    int textThreshold = _kDefaultTextThreshold,
  }) {
    final contentLines = syncedTarget.lyrics
        .where((l) => l.text.trim().isNotEmpty)
        .toList();
    if (contentLines.isEmpty) return 0;

    int matched = 0;
    for (final line in contentLines) {
      // Quick exact-timestamp check.
      final src = _findByTimestamp(
        line,
        richSource.lyrics,
        _kTimestampToleranceMs,
      );
      if (src != null && (src.inlineParts?.isNotEmpty ?? false)) {
        final sim = _similarity(line.text, src.text);
        if (sim >= textThreshold || src.startTime == line.startTime) {
          matched++;
          continue;
        }
      }
      // Fallback: text similarity.
      for (final s in richSource.lyrics) {
        if (s.inlineParts == null || s.inlineParts!.isEmpty) continue;
        if (_similarity(line.text, s.text) >= textThreshold) {
          matched++;
          break;
        }
      }
    }
    return matched / contentLines.length;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static Lyric? _findByTimestamp(
    Lyric target,
    List<Lyric> source,
    int toleranceMs,
  ) {
    Lyric? best;
    int bestDiff = toleranceMs + 1;
    for (final s in source) {
      final diff =
          (s.startTime.inMilliseconds - target.startTime.inMilliseconds).abs();
      if (diff <= toleranceMs && diff < bestDiff) {
        bestDiff = diff;
        best = s;
      }
    }
    return best;
  }

  /// Copy [inlineParts] from [src] onto [target], re-anchoring each part's
  /// timestamps by the offset between the two lines' start times.  This keeps
  /// the karaoke highlight correct even when the sources differ slightly.
  static Lyric _mergeInlineParts(Lyric target, Lyric src) {
    final offsetMs =
        target.startTime.inMilliseconds - src.startTime.inMilliseconds;
    final adjustedParts = src.inlineParts!.map((p) {
      return LyricInlinePart(
        startTime: Duration(
          milliseconds: (p.startTime.inMilliseconds + offsetMs).clamp(
            0,
            999999,
          ),
        ),
        endTime: Duration(
          milliseconds: (p.endTime.inMilliseconds + offsetMs).clamp(0, 999999),
        ),
        text: p.text,
      );
    }).toList();

    return Lyric(
      startTime: target.startTime,
      endTime: target.endTime,
      text: target.text,
      inlineParts: adjustedParts,
      translation: target.translation,
    );
  }

  static int _similarity(String a, String b) {
    final ca = a.toLowerCase().trim();
    final cb = b.toLowerCase().trim();
    if (ca.isEmpty || cb.isEmpty) return 0;
    try {
      return (StringSimilarity.compareTwoStrings(ca, cb) * 100).toInt();
    } catch (_) {
      return 0;
    }
  }
}
