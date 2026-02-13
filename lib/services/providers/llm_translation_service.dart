import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../settings_service.dart';

class LlmTranslationService {
  bool checkTranslationSupport(String language) {
    return true;
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
        debugPrint('LLM Translation: Endpoint or API Key is empty.');
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
          'You are a professional translator. Translate the following song lyrics into $targetLanguage. '
          ''
          'REQUIREMENTS:'
          '  - Your response MUST be ONLY a raw JSON array of strings. The array must contain exactly ${linesToTranslate.length} strings, corresponding one-to-one with the input lines. Do not return markdown code blocks, just the raw JSON. '
          '  - If a line is empty or instrumental, return an empty string for it.'
          'TRANSLATION GUIDELINES:'
          '  - Preserve the emotional tone and poetic style of the original lyrics'
          '  - Adapt cultural-specific terms naturally'
          '  - Maintain rhythm and singability where possible'
          '  - Prioritize faithfulness, expressiveness, and elegance'
          'FORBIDDEN:'
          '  - DO NOT add explanations before or after the JSON'
          '  - DO NOT use markdown code blocks (```'
          '  - DO NOT include any text outside the JSON object'
          '  - DO NOT add comments or notes';

      final messages = [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': jsonEncode(linesToTranslate)},
      ];

      // 3. Call LLM API
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model.isNotEmpty ? model : 'openai/gpt-oss-120b',
          'messages': messages,
          'temperature': 0.3,
        }),
      );
      // final response = await http.get(
      //   Uri.parse("http://localhost:3000/1.json"),
      // );

      if (response.statusCode != 200) {
        debugPrint(
          'LLM Translation Failed: ${response.statusCode} ${response.body}',
        );
        return LyricsResult.empty();
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final content = jsonResponse['choices']?[0]?['message']?['content'];

      if (content == null) {
        return LyricsResult.empty();
      }

      String cleanContent = content.trim();
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

      List<dynamic> translatedLines;
      try {
        translatedLines = jsonDecode(cleanContent);
      } catch (e) {
        debugPrint(
          'LLM Translation JSON Parse Error: $e\nContent: $cleanContent',
        );
        return LyricsResult.empty();
      }

      if (translatedLines.length != originalLyrics.length) {
        debugPrint(
          'LLM Translation Mismatch: Input ${originalLyrics.length} vs Output ${translatedLines.length}',
        );
        debugPrint('originalLyrics: $originalLyrics');
        debugPrint('translatedLines: $translatedLines');
        // Fallback: Try to map as many as possible or abort?
        // If mismatch is small, maybe just map min length.
        // But safe to return empty for now to avoid bad sync.
        // Actually, let's map min length.
      }

      final List<Lyric> newLyrics = [];
      final count = translatedLines.length < originalLyrics.length
          ? translatedLines.length
          : originalLyrics.length;

      for (int i = 0; i < count; i++) {
        final original = originalLyrics[i];
        final translation = translatedLines[i].toString();
        // We set the TEXT to the translation, because this result will be used as subLyrics (translation)
        // logic in lyrics_service sets subLyrics = transResult
        newLyrics.add(
          Lyric(
            startTime: original.startTime,
            endTime: original.endTime,
            text: translation,
          ),
        );
      }

      return LyricsResult(
        lyrics: newLyrics,
        source: 'LLM ($model)',
        translation: true,
      );
    } catch (e) {
      debugPrint('LLM Translation Error: $e');
      return LyricsResult.empty();
    }
  }
}
