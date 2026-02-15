import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../settings_service.dart';

class LlmTranslationService {
  bool checkTranslationSupport(String language) {
    if (language.startsWith('llm:')) {
      return true;
    }
    return false;
  }

  final SettingsService _settingsService;

  LlmTranslationService(this._settingsService);

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data,
    String targetLanguage,
  ) async {
    targetLanguage = targetLanguage
        .substring(4)
        .trim(); // remove the "llm:" prefix
    try {
      final endpoint = (await _settingsService.getLlmApiEndpoint()).current;
      final apiKey = (await _settingsService.getLlmApiKey()).current;
      final model = (await _settingsService.getLlmModel()).current;

      if (endpoint.isEmpty || apiKey.isEmpty) {
        debugPrint('[LLM Translation] Endpoint or API Key is empty.');
        return LyricsResult.empty();
      }

      // 1. Parse original content to get lines
      final parsed = LrcParser.parse(data.content);
      final originalLyrics = parsed.lyrics;

      if (originalLyrics.isEmpty) {
        return LyricsResult.empty();
      }

      final linesToTranslate = originalLyrics.map((l) => l.text).toList();

      // 2. Construct Prompt
      final prompt =
          '''

Song Metadata:
Title: ${data.title}
Artist: ${data.artist}

Requirements:
1. The output MUST be a raw JSON (see definition below).
2. Preserve the poetic style, emotional tone, and rhythm.
3. If a line is empty or instrumental, return an empty string.
4. DO NOT use Markdown formatting (no codeblock like \\`\\`\\`json). Output raw JSON only.
5. DO NOT add comments or notes.

Target Language: $targetLanguage
Instructions:
1. Detect the source language of the lyrics.
2. If translation is not needed (eg. the source language is the same as the target language), return "SKIP".
3. If the source language is different from the target language, 
   translate the lyrics to the target language following the structure

Fake code of this instructions:
```typescript
const linesToTranslate: string[] = ${jsonEncode(linesToTranslate)}

type TranslatedLine = {original: string, translated: string};
function Translate(
  lyrics: string[], 
  sourceLanguage: string, 
  targetLanguage: string
): TranslatedLine[] {
  if (sourceLanguage == targetLanguage) {
    return ["SKIP"];
  } else {
    return lyrics.map((line) => {original: line, translated: translateLine(line)});
  }
}
const sourceLanguage = detectSourceLanguage(linesToTranslate);
return new Response(
  JSON.stringify(
    {
      translation: Translate(linesToTranslate, sourceLanguage, targetLanguage),
      metadata: {
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      }
    }
  )
);
''';
      // 3. Call LLM API
      final int start = FlutterTimeline.now;
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model.isNotEmpty ? model : 'openai/gpt-oss-120b',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional translator specialized in song lyrics.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.35,
          'stream': false,
          'max_tokens': 1000000,
        }),
      );
      final int end = FlutterTimeline.now;
      final int requestElapsed = (end - start) ~/ 1000;
      debugPrint('[LLM Translation] Request Elapsed: $requestElapsed ms');

      if (response.statusCode != 200) {
        debugPrint(
          '[LLM Translation] Failed: ${response.statusCode} ${response.body}',
        );
        return LyricsResult.empty();
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final content = jsonResponse['choices']?[0]?['message']?['content'];

      if (content == null) {
        return LyricsResult.empty();
      }

      String cleanContent = content.trim();

      // Handle SKIP response (case-insensitive and trimmed)
      if (cleanContent.toUpperCase() == 'SKIP') {
        return LyricsResult(
          lyrics: originalLyrics,
          source: 'SKIPPED',
          translation: false,
        );
      }
      // Remove markdown code blocks if present
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      } else if (cleanContent.startsWith('```')) {
        cleanContent = cleanContent.substring(3);
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }
      cleanContent = cleanContent.trim();

      dynamic translatedLines;
      try {
        translatedLines = jsonDecode(cleanContent)['translation'];
      } catch (e) {
        debugPrint(
          '[LLM Translation] JSON Parse Error: $e\nContent: $cleanContent',
        );
        return LyricsResult.empty();
      }

      // Handle SKIP response (case-insensitive and trimmed)
      if ((translatedLines is String &&
              translatedLines.toUpperCase() == 'SKIP') ||
          (translatedLines is List &&
              translatedLines.length == 1 &&
              translatedLines[0].toString().toUpperCase() == 'SKIP')) {
        return LyricsResult(
          lyrics: originalLyrics,
          source: 'SKIPPED',
          translation: false,
        );
      }

      if (translatedLines is! List) {
        debugPrint(
          '[LLM Translation] Error: Model produced malformed JSON. Expected List or "SKIP", got $translatedLines',
        );
        return LyricsResult.empty();
      }

      final List<Lyric> newLyrics = [];
      int nextSearchStartIndex = 0;
      for (var line in originalLyrics) {
        for (int i = nextSearchStartIndex; i < translatedLines.length; i++) {
          if (_calcLineSimilarity(line.text, translatedLines[i]['original']) >
              80) {
            newLyrics.add(
              Lyric(
                startTime: line.startTime,
                endTime: line.endTime,
                text: translatedLines[i]['translated'],
              ),
            );
            nextSearchStartIndex = i + 1;
            break;
          }
        }
      }

      return LyricsResult(
        lyrics: newLyrics,
        source: 'LLM Translation',
        language: targetLanguage,
        translation: true,
        translationProvider: 'LLM Translation',
        translationContributor:
            'Model $model, Request Elapsed ${requestElapsed / 1000}s',
      );
    } catch (e) {
      debugPrint('[LLM Translation] Error: $e');
      return LyricsResult.empty();
    }
  }
}

int _calcLineSimilarity(String line1, String line2) {
  // 1. Simple normalization
  String clean1 = line1.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  String clean2 = line2.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

  // 2. Calculate similarity (0-100)
  int score = ratio(clean1, clean2);

  // 3. Return true if similarity is above 80%
  return score;
}
