import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/string_similarity.dart';
import '../../utils/translation_helper.dart';

class NeteaseService {
  bool checkTranslationSupport(String language) {
    return language == 'zh_CN';
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool trimMetadata = false,
    int translationBias = 0,
    bool useStandardLyricsForPairing = false,
    Function(String)? onArtworkUrl,
    Function(LyricsResult)? onTranslation,
  }) async {
    try {
      onStatusUpdate?.call('[NeteaseMusic] Searching songs...');
      final bestMatch = await _searchSong(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
      );

      if (bestMatch == null) {
        return LyricsResult.empty();
      }

      final songId = bestMatch['id'].toString();
      final artworkUrl =
          bestMatch['al']?['picUrl'] ?? bestMatch['album']?['picUrl'];

      if (artworkUrl != null) {
        onArtworkUrl?.call(artworkUrl);
      }

      onStatusUpdate?.call('[NeteaseMusic] Fetching lyrics...');
      final lyricData = await _getLyrics(
        songId,
        trimMetadata,
        translationBias,
        useStandardLyricsForPairing,
        onTranslation,
      );

      if (lyricData == null) {
        return LyricsResult.empty();
      }

      return lyricData;
    } catch (e) {
      debugPrint('[NeteaseMusic] Error fetching lyrics: $e');
    }
    return LyricsResult.empty();
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data, {
    int translationBias = 0,
    bool useStandardLyricsForPairing = false,
  }) async {
    try {
      LyricsResult? translationResult;
      await fetchLyrics(
        title: data.title,
        artist: data.artist,
        durationSeconds: data.durationSeconds,
        translationBias: translationBias,
        useStandardLyricsForPairing: useStandardLyricsForPairing,
        onTranslation: (trans) {
          translationResult = trans;
        },
      );

      return translationResult ?? LyricsResult.empty();
    } catch (e) {
      debugPrint('[NeteaseMusic] Error fetching translation: $e');
    }
    return LyricsResult.empty();
  }

  static const Map<String, String> _headers = {
    'Referer': 'https://music.163.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  };

  Future<Map<String, dynamic>?> _searchSong({
    required String title,
    required String artist,
    int durationSeconds = 0,
  }) async {
    try {
      final keyword = '$title - $artist';
      final searchUrl = Uri.parse('https://music.163.com/api/search/get/web');
      final searchParams = {
        's': keyword,
        'type': '1', // 1 for song
        'offset': '0',
        'limit': '20',
      };

      final searchResponse = await http
          .post(searchUrl, headers: _headers, body: searchParams)
          .timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        return null;
      }

      final searchData = jsonDecode(searchResponse.body);
      final songList = searchData['result']?['songs'] as List? ?? [];
      if (songList.isEmpty) {
        return null;
      }

      // Filter songs
      final filteredSongs = songList.where((song) {
        final songName = song['name'] as String?;
        if (songName == null) return false;

        final similarity = JaroWinklerSimilarity.getJaroWinklerScore(
          title.toLowerCase(),
          songName.toLowerCase(),
        );

        return similarity >= 0.7;
      }).toList();

      if (filteredSongs.isEmpty) {
        return null;
      }

      // Find the best match based on duration
      dynamic bestMatch = filteredSongs[0];
      double minDiff = 1000000;

      for (var song in filteredSongs) {
        final songDuration = song['duration']; // Duration in ms
        if (songDuration != null && songDuration is int) {
          final diff = (songDuration - (durationSeconds * 1000))
              .abs()
              .toDouble();
          if (diff < 1000) {
            bestMatch = song;
            minDiff = 0;
            break;
          } else if (diff < minDiff) {
            minDiff = diff;
            bestMatch = song;
          }
        }
      }

      return bestMatch;
    } catch (e) {
      debugPrint('[NeteaseMusic] Error searching song: $e');
      return null;
    }
  }

  Future<LyricsResult?> _getLyrics(
    String songId,
    bool trimMetadata,
    int translationBias,
    bool useStandardLyricsForPairing,
    Function(LyricsResult)? onTranslation,
  ) async {
    try {
      final lyricUri = Uri.parse('https://music.163.com/api/song/lyric')
          .replace(
            queryParameters: {
              'id': songId,
              'lv': '1',
              'kv': '1',
              'tv': '-1',
              'rv': '-1',
              'yv': '-1',
              'ytv': '-1',
              'yrv': '-1',
              'csrf_token': '',
            },
          );

      final lyricResponse = await http
          .get(lyricUri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (lyricResponse.statusCode != 200) {
        return null;
      }

      final lyricData = jsonDecode(lyricResponse.body);

      final String? lrc = lyricData['lrc']?['lyric'];
      final String? yrc = lyricData['yrc']?['lyric'];
      final String? tlyric = lyricData['tlyric']?['lyric'];
      final bool isPureMusic = lyricData['pureMusic'] == true;

      final String? lyricContributor = lyricData['lyricUser']?['nickname'];
      final String? translationContributor =
          lyricData['transUser']?['nickname'];

      if ((lrc != null && lrc.isNotEmpty) ||
          (yrc != null && yrc.isNotEmpty) ||
          (tlyric != null && tlyric.isNotEmpty) ||
          isPureMusic) {
        List<Lyric> richLyrics = [];
        List<Lyric> lyrics = [];
        Map<String, String> trimmedMetadata = {};

        if (yrc != null && yrc.isNotEmpty) {
          richLyrics = _NeteaseYrcParser.parse(yrc);
          if (trimMetadata) {
            final trimResult = LrcParser.trimMetadataLines(richLyrics);
            richLyrics = trimResult.lyrics;
            trimmedMetadata = trimResult.trimmedMetadata;
          }
        }

        if (lrc != null && lrc.isNotEmpty) {
          final parseResult = LrcParser.parse(lrc, trimMetadata: trimMetadata);
          lyrics = parseResult.lyrics;
          trimmedMetadata = parseResult.trimmedMetadata;
        }

        if (tlyric != null && tlyric.isNotEmpty) {
          final transParse = LrcParser.parse(tlyric);
          if (transParse.lyrics.isNotEmpty) {
            final rawTranslation = TranslationHelper.pair(
              originalLyrics: useStandardLyricsForPairing
                  ? lyrics
                  : (richLyrics.isNotEmpty ? richLyrics : lyrics),
              translatedLyrics: transParse.lyrics,
              translationBias: translationBias,
            );

            onTranslation?.call(
              LyricsResult(
                lyrics: [],
                rawTranslation: rawTranslation,
                source: 'Netease Music',
                isSynced: true,
                language: 'zh_CN',
                translation: true,
                translationProvider: 'Netease Music',
                translationContributor: translationContributor,
              ),
            );
          }
        }

        return LyricsResult(
          lyrics: richLyrics.isNotEmpty ? richLyrics : lyrics,
          source: 'Netease Music',
          isPureMusic: isPureMusic,
          contributor: lyricContributor,
          metadata: trimmedMetadata,
        );
      }
    } catch (e) {
      debugPrint('[NeteaseMusic] Error fetching lyrics: $e');
    }
    return null;
  }
}

class _NeteaseYrcParser {
  static List<Lyric> parse(String yrcContent) {
    final List<Lyric> lyrics = [];
    // Pattern for line: [lineStartTime,lineDuration](wordStartTime,wordDuration,0)Word...
    final lineRegex = RegExp(r'\[(\d+),(\d+)\](.*)');
    final wordRegex = RegExp(r'\((\d+),(\d+),\d+\)([^\(\[]*)');

    final lines = yrcContent.split('\n');
    for (var lineStr in lines) {
      final lineMatch = lineRegex.firstMatch(lineStr);
      if (lineMatch != null) {
        final int lineStart = int.parse(lineMatch.group(1)!);
        final int lineDuration = int.parse(lineMatch.group(2)!);
        final String wordsContent = lineMatch.group(3)!;

        final List<LyricInlinePart> inlineParts = [];
        final Iterable<Match> wordMatches = wordRegex.allMatches(wordsContent);

        String fullText = '';
        for (final wordMatch in wordMatches) {
          final int wordStart = int.parse(wordMatch.group(1)!);
          final int wordDuration = int.parse(wordMatch.group(2)!);
          final String wordText = wordMatch.group(3)!;

          fullText += wordText;
          inlineParts.add(
            LyricInlinePart(
              startTime: Duration(milliseconds: wordStart),
              endTime: Duration(milliseconds: wordStart + wordDuration),
              text: wordText,
            ),
          );
        }

        // If no word matches were found, it might be a metadata line or empty line
        if (inlineParts.isEmpty) {
          // Check if it's metadata like [0,730](0,730,0) 作词 : ...
          // The wordRegex should have caught it if it follows the pattern.
          // In the example: [0,730](0,730,0) 作词 : Ryosuke \"Dr. R\" Sakai/milet
          // wordStart=0, wordDuration=730, wordText=" 作词 : Ryosuke \"Dr. R\" Sakai/milet"
          // So it should be caught.
        }

        lyrics.add(
          Lyric(
            startTime: Duration(milliseconds: lineStart),
            endTime: Duration(milliseconds: lineStart + lineDuration),
            text: fullText.isEmpty ? wordsContent : fullText,
            inlineParts: inlineParts.isNotEmpty ? inlineParts : null,
          ),
        );
      }
    }

    return lyrics;
  }
}
