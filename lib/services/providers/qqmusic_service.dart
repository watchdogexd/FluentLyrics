import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/string_similarity.dart';
import '../../utils/translation_helper.dart';

class QQMusicService {
  bool checkTranslationSupport(String language) {
    return language == 'zh_CN';
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool trimMetadata = false,
    int translationBias = 0,
    bool useStandardLyricsForPairing = false,
  }) async {
    try {
      onStatusUpdate?.call('[QQMusic] Searching songs...');

      final bestMatch = await _searchSong(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
      );

      if (bestMatch == null) {
        return LyricsResult.empty();
      }

      // 3. Fetch Lyrics
      final songMid = bestMatch['mid'] as String;
      // Extract album mid for artwork if available
      final albumMid = bestMatch['album']?['mid'] as String?;
      String? artworkUrl;
      if (albumMid != null && albumMid.isNotEmpty) {
        artworkUrl =
            'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
      }

      onStatusUpdate?.call('[QQMusic] Fetching lyrics...');

      final lyricsResponse = await _getLyrics(songMid);
      if (lyricsResponse == null) {
        debugPrint('[QQMusic] Lyrics response for best match is null');
        return LyricsResult.empty();
      }

      String? lrc = lyricsResponse['lyric'];
      String? trans = lyricsResponse['trans'];

      if (lrc != null && lrc.isNotEmpty) {
        lrc = utf8.decode(base64.decode(lrc));
      }
      if (trans != null && trans.isNotEmpty) {
        try {
          trans = utf8.decode(base64.decode(trans));
        } catch (e) {
          trans = null;
        }
      }

      if (lrc != null && lrc.isNotEmpty) {
        onStatusUpdate?.call('[QQMusic] Processing lyrics...');

        final parseResult = LrcParser.parse(lrc, trimMetadata: trimMetadata);

        // Parse translation
        LyricsResult? subLyrics;
        if (trans != null && trans.isNotEmpty) {
          final transParse = LrcParser.parse(trans);
          if (transParse.lyrics.isNotEmpty) {
            final rawTranslation = TranslationHelper.pair(
              originalLyrics: parseResult.lyrics,
              translatedLyrics: transParse.lyrics,
              translationBias: translationBias,
            );

            subLyrics = LyricsResult(
              lyrics: [],
              rawTranslation: rawTranslation,
              source: 'QQ Music',
              isSynced: true,
              translation: true,
              language: 'zh_CN',
              translationProvider: 'QQ Music',
            );
          }
        }

        return LyricsResult(
          lyrics: parseResult.lyrics,
          source: 'QQ Music',
          artworkUrl: artworkUrl,
          writtenBy:
              parseResult.trimmedMetadata['作词'] ??
              parseResult.trimmedMetadata['作詞'] ??
              parseResult.trimmedMetadata['Lyrics by'],
          composer:
              parseResult.trimmedMetadata['作曲'] ??
              parseResult.trimmedMetadata['Composer'] ??
              parseResult.trimmedMetadata['Composed by'],
          isPureMusic: false,
          subLyrics: subLyrics,
          metadata: {
            ...parseResult.lrcMetadata,
            ...parseResult.trimmedMetadata,
          },
        );
      }

      return LyricsResult.empty();
    } catch (e) {
      debugPrint('[QQMusic] Error fetching lyrics: $e');
      return LyricsResult.empty();
    }
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data, {
    int translationBias = 0,
    bool useStandardLyricsForPairing = false,
  }) async {
    try {
      final lyricData = await fetchLyrics(
        title: data.title,
        artist: data.artist,
        album: data.album,
        durationSeconds: data.durationSeconds,
        translationBias: translationBias,
        useStandardLyricsForPairing: useStandardLyricsForPairing,
      );

      if (lyricData.subLyrics == null) {
        return LyricsResult.empty();
      } else {
        return lyricData.subLyrics!;
      }
    } catch (e) {
      debugPrint('[QQMusic] Error fetching translation: $e');
    }
    return LyricsResult.empty();
  }

  static const Map<String, String> _headers = {
    'Referer': 'https://c.y.qq.com/',
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
      final searchUrl = Uri.parse('https://u.y.qq.com/cgi-bin/musicu.fcg');
      final searchBody = {
        'req_1': {
          'method': 'DoSearchForQQMusicDesktop',
          'module': 'music.search.SearchCgiService',
          'param': {
            'num_per_page': 20,
            'page_num': 1,
            'query': keyword,
            'search_type': 0, // 0 for song
          },
        },
      };

      final searchResponse = await http
          .post(searchUrl, headers: _headers, body: jsonEncode(searchBody))
          .timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        debugPrint('[QQMusic] Search failed: ${searchResponse.statusCode}');
        return null;
      }

      final searchData = jsonDecode(utf8.decode(searchResponse.bodyBytes));
      final req1 = searchData['req_1'];
      if (req1['code'] != 0) {
        debugPrint('[QQMusic] Search API error: ${req1['code']}');
        return null;
      }

      final songList = req1['data']['body']['song']['list'] as List? ?? [];
      if (songList.isEmpty) {
        debugPrint('[QQMusic] Search returned no songs');
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
        debugPrint(
          '[QQMusic] Search returned songs but none matched the title similarity threshold.',
        );
        return null;
      }

      // Find the best match based on duration
      dynamic bestMatch = filteredSongs[0];
      double minDiff = 1000000;

      for (var song in filteredSongs) {
        final songDuration = song['interval']; // Duration in seconds
        if (songDuration != null && songDuration is int) {
          final diff = (songDuration - durationSeconds).abs().toDouble();
          if (diff < 1) {
            bestMatch = song;
            minDiff = 0;
            break;
          } else if (diff < minDiff) {
            minDiff = diff;
            bestMatch = song;
          }
        }
      }

      if (minDiff > 10 && durationSeconds > 0 && minDiff != 1000000) {
        debugPrint('[QQMusic] Best match duration diff too large: ${minDiff}s');
      }

      return bestMatch;
    } catch (e) {
      debugPrint('[QQMusic] Error searching song: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getLyrics(String songMid) async {
    try {
      final uri = Uri.parse(
        'https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
      );
      final headers = Map<String, String>.from(_headers);
      headers['Referer'] = 'https://c.y.qq.com/';

      final body = {
        'songmid': songMid,
        'g_tk': '5381',
        'format': 'json', // Try json first instead of jsonp
        'inCharset': 'utf8',
        'outCharset': 'utf8',
        'notice': '0',
        'platform': 'yqq',
        'needNewCode': '0',
      };

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // If format=json works, great.
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // If it returns JSONP even with format=json, stripping is needed.
          // Or if format=json is ignored.
          String body = response.body;
          if (body.startsWith('MusicJsonCallback_lrc(')) {
            body = body.substring(
              'MusicJsonCallback_lrc('.length,
              body.length - 1,
            );
            return jsonDecode(body);
          }
        }
      }
    } catch (e) {
      debugPrint('[QQMusic] Cannot fetch lyrics: $e');
    }
    return null;
  }
}
