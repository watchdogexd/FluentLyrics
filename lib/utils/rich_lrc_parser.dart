import 'dart:convert';
import '../models/lyric_model.dart';
import 'package:flutter/foundation.dart';

class MusixmatchRichParser {
  static List<Lyric> parse(String jsonString) {
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((line) {
        final double ts = (line['ts'] as num).toDouble();
        final double te = (line['te'] as num).toDouble();
        final String text = line['x'] ?? '';
        final List<dynamic>? parts = line['l'];

        List<LyricInlinePart>? inlineParts;
        if (parts != null) {
          inlineParts = [];
          for (int i = 0; i < parts.length; i++) {
            final part = parts[i];
            final String charText = part['c'] ?? '';
            final double offset = (part['o'] as num).toDouble();

            final startTime = Duration(
              milliseconds: ((ts + offset) * 1000).toInt(),
            );

            // Estimate end time based on next part's offset or line end time
            double nextOffset;
            if (i < parts.length - 1) {
              nextOffset = (parts[i + 1]['o'] as num).toDouble();
            } else {
              nextOffset = te - ts;
            }

            final endTime = Duration(
              milliseconds: ((ts + nextOffset) * 1000).toInt(),
            );

            inlineParts.add(
              LyricInlinePart(
                startTime: startTime,
                endTime: endTime,
                text: charText,
              ),
            );
          }
        }

        return Lyric(
          startTime: Duration(milliseconds: (ts * 1000).toInt()),
          endTime: Duration(milliseconds: (te * 1000).toInt()),
          text: text,
          inlineParts: inlineParts,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing Musixmatch rich sync: $e');
      return [];
    }
  }
}

class EnhancedLrcParser {
  static List<Lyric> parse(String content) {
    final List<Lyric> lyrics = [];
    final lineRegex = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    final wordRegex = RegExp(r'<(\d+):(\d+\.\d+)>(.[^<]*)');

    final lines = content.split('\n');
    for (var lineStr in lines) {
      final lineMatch = lineRegex.firstMatch(lineStr);
      if (lineMatch != null) {
        final minutes = int.parse(lineMatch.group(1)!);
        final seconds = double.parse(lineMatch.group(2)!);
        final String wordsContent = lineMatch.group(3)!;

        final startTime = Duration(
          minutes: minutes,
          milliseconds: (seconds * 1000).toInt(),
        );

        final List<LyricInlinePart> inlineParts = [];
        final Iterable<Match> wordMatches = wordRegex.allMatches(wordsContent);

        String fullText = '';
        List<Match> matches = wordMatches.toList();
        for (int i = 0; i < matches.length; i++) {
          final match = matches[i];
          final wMin = int.parse(match.group(1)!);
          final wSec = double.parse(match.group(2)!);
          final String wordText = match.group(3)!;

          final wStart = Duration(
            minutes: wMin,
            milliseconds: (wSec * 1000).toInt(),
          );
          fullText += wordText;

          Duration wEnd;
          if (i < matches.length - 1) {
            final nextMatch = matches[i + 1];
            final nMin = int.parse(nextMatch.group(1)!);
            final nSec = double.parse(nextMatch.group(2)!);
            wEnd = Duration(minutes: nMin, milliseconds: (nSec * 1000).toInt());
          } else {
            // We'll fix line end time later and then update this
            wEnd = wStart + const Duration(milliseconds: 500);
          }

          inlineParts.add(
            LyricInlinePart(startTime: wStart, endTime: wEnd, text: wordText),
          );
        }

        lyrics.add(
          Lyric(
            startTime: startTime,
            text: fullText.isEmpty ? wordsContent.trim() : fullText,
            inlineParts: inlineParts.isNotEmpty ? inlineParts : null,
          ),
        );
      }
    }

    // Sort and calculate end times
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));
    for (int i = 0; i < lyrics.length; i++) {
      Duration? lineEnd;
      if (i < lyrics.length - 1) {
        lineEnd = lyrics[i + 1].startTime;
      }

      if (lineEnd != null) {
        final current = lyrics[i];
        lyrics[i] = Lyric(
          startTime: current.startTime,
          endTime: lineEnd,
          text: current.text,
          inlineParts: current.inlineParts,
        );

        // Update the last word's end time to the line's end time if it exceeds it or is the placeholder
        if (current.inlineParts != null && current.inlineParts!.isNotEmpty) {
          final lastPart = current.inlineParts!.last;
          if (lastPart.endTime < lastPart.startTime ||
              lastPart.endTime ==
                  lastPart.startTime + const Duration(milliseconds: 500)) {
            // update last part end time
            final newParts = List<LyricInlinePart>.from(current.inlineParts!);
            newParts[newParts.length - 1] = LyricInlinePart(
              startTime: lastPart.startTime,
              endTime: lineEnd,
              text: lastPart.text,
            );
            lyrics[i] = Lyric(
              startTime: current.startTime,
              endTime: lineEnd,
              text: current.text,
              inlineParts: newParts,
            );
          }
        }
      }
    }

    return lyrics;
  }
}
