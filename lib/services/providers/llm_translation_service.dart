import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
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
    try {
      final endpoint = (await _settingsService.getLlmApiEndpoint()).current;
      final apiKey = (await _settingsService.getLlmApiKey()).current;
      final model = (await _settingsService.getLlmModel()).current;

      if (endpoint.isEmpty || apiKey.isEmpty) {
        debugPrint('[LLM Translation] Endpoint or API Key is empty.');
        return LyricsResult.empty();
      }
      // check for dummy endpoint
      final host = Uri.parse(endpoint).host;
      if (host.contains('dummy.endpoint.example')) {
        debugPrint('[LLM Translation] Endpoint is dummy, skipping.');
        return LyricsResult.empty();
      }

      final llmReasoningEffort =
          (await _settingsService.getLlmReasoningEffort()).current;

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
4. You MUST NOT use Markdown formatting (no codeblock like \\`\\`\\`json). Output raw JSON only.
5. You MUST NOT add comments or notes.

Target Language: ${targetLanguage.substring(4).trim()}
Instructions:
1. Detect the source language of the lyrics.
2. If translation is not needed (eg. the source language is the same as the target language), return "SKIP".
3. If the source language is different from the target language, 
   translate the lyrics to the target language following the structure
4. If the source language is as same as the target language, you MUST ONLY return "SKIP".

Fake code of the instruction:
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

      final Map<String, dynamic> requestBody = {
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
      };

      if (llmReasoningEffort != 'auto') {
        requestBody['reasoning_effort'] = llmReasoningEffort;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
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

      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      String? content = jsonResponse['choices']?[0]?['message']?['content']
          ?.trim();

      // try strip out <thought></thought> block
      if (content != null) {
        final thoughtPattern = RegExp(
          r'<thought>.*?</thought>(.*)',
          multiLine: true,
          dotAll: true,
        );
        final match = thoughtPattern.firstMatch(content);
        if (match != null) {
          content = match.group(1);
        }
      }

      if (content == null) {
        return LyricsResult.empty();
      }

      // Handle SKIP response (case-insensitive and trimmed)
      if (content.toUpperCase() == 'SKIP') {
        return LyricsResult(
          lyrics: originalLyrics,
          source: 'SKIPPED',
          translation: false,
        );
      }
      dynamic translatedLines;
      // try to decode raw as json directly
      try {
        jsonResponse = jsonDecode(content);
        translatedLines = jsonResponse['translation'];
      } catch (e) {
        debugPrint(
          '[LLM Translation] Fail to parse response as raw JSON, trying to strip...',
        );
        try {
          // check if markdown codeblock present
          final codeblockPattern = RegExp(
            r'\`\`\`(?:.*)\n([\s\S]*?)\n\s*\`\`\`',
          );

          final match = codeblockPattern.allMatches(content);
          if (match.isNotEmpty) {
            // try every group until we found a valid response
            for (var m in match) {
              final codeblockContent = m.group(1);
              if (codeblockContent != null) {
                try {
                  jsonResponse = jsonDecode(codeblockContent);
                  translatedLines = jsonResponse['translation'];
                  if (translatedLines != null) {
                    break;
                  }
                } catch (e) {
                  continue;
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
            '[LLM Translation] Error: Model produced malformed JSON. Expected List or "SKIP", got $translatedLines',
          );
        }
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

      final List<Map<String, String>> rawTranslation = [];
      for (var item in translatedLines) {
        if (item is Map) {
          rawTranslation.add({
            'original': item['original']?.toString() ?? '',
            'translated': item['translated']?.toString() ?? '',
          });
        }
      }

      return LyricsResult(
        lyrics: [],
        rawTranslation: rawTranslation,
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
