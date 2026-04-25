import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/translation_helper.dart';
import '../../utils/song_result_helper.dart';

class QQMusicService {
  static const int lyricEmptyRetryCount = 3;
  bool checkTranslationSupport(String language) {
    return language == 'zh_CN';
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool trimMetadata = false,
    int translationBias = 0,
    Function(String)? onArtworkUrl,
    Function(LyricsResult)? onTranslation,
  }) async {
    try {
      onStatusUpdate?.call('[QQMusic] Searching songs...');

      final bestMatch = await _searchSongs(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
      );

      if (bestMatch.isEmpty) {
        return LyricsResult.empty();
      }

      final maxRetryCount = min(lyricEmptyRetryCount, bestMatch.length);

      for (int i = 0; i < maxRetryCount; i++) {
        // 3. Fetch Lyrics
        final songMid = bestMatch[i].data['mid'] as String;
        // Extract album mid for artwork if available
        final albumMid = bestMatch[i].data['album']?['mid'] as String?;
        if (albumMid != null && albumMid.isNotEmpty) {
          onArtworkUrl?.call(
            'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg',
          );
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

          if (trans != null && trans.isNotEmpty) {
            final transParse = LrcParser.parse(trans);
            if (transParse.lyrics.isNotEmpty) {
              final rawTranslation = TranslationHelper.pair(
                originalLyrics: parseResult.lyrics,
                translatedLyrics: transParse.lyrics,
                translationBias: translationBias,
              );

              onTranslation?.call(
                LyricsResult(
                  lyrics: [],
                  rawTranslation: rawTranslation,
                  source: 'QQ Music',
                  isSynced: true,
                  translation: true,
                  language: 'zh_CN',
                  translationProvider: 'QQ Music',
                ),
              );
            }
          }

          return LyricsResult(
            lyrics: parseResult.lyrics,
            source: 'QQ Music',
            writtenBy:
                parseResult.trimmedMetadata['作词'] ??
                parseResult.trimmedMetadata['作詞'] ??
                parseResult.trimmedMetadata['Lyrics by'],
            composer:
                parseResult.trimmedMetadata['作曲'] ??
                parseResult.trimmedMetadata['Composer'] ??
                parseResult.trimmedMetadata['Composed by'],
            isPureMusic: false,
            metadata: {
              ...parseResult.lrcMetadata,
              ...parseResult.trimmedMetadata,
            },
          );
        }

        onStatusUpdate?.call(
          '[QQMusic] No lyrics found for songMid $songMid, trying next song (${i + 1}/$maxRetryCount)...',
        );
        debugPrint(
          '[QQMusic] No lyrics found for songMid $songMid, trying next song (${i + 1}/$maxRetryCount)...',
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
  }) async {
    try {
      LyricsResult? translationResult;
      await fetchLyrics(
        title: data.title,
        artist: data.artist,
        durationSeconds: data.durationSeconds,
        translationBias: translationBias,
        onTranslation: (trans) {
          translationResult = trans;
        },
      );

      return translationResult ?? LyricsResult.empty();
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

  Future<List<ProcessedSong>> _searchSongs({
    required String title,
    required List<String> artist,
    int durationSeconds = 0,
  }) async {
    try {
      final keywordList = ['$title - ${artist.join(', ')}', title];
      for (var keyword in keywordList) {
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
          continue;
        }

        final searchData = jsonDecode(utf8.decode(searchResponse.bodyBytes));
        final req1 = searchData['req_1'];
        if (req1['code'] != 0) {
          debugPrint('[QQMusic] Search API error: ${req1['code']}');
          continue;
        }

        final songList = req1['data']['body']['song']['list'] as List? ?? [];
        if (songList.isEmpty) {
          debugPrint('[QQMusic] Search returned no songs');
          continue;
        }

        // convert to GenericSongs
        List<GenericSong> genericSongs = [];
        for (var song in songList) {
          final songName = song['name'] as String?;
          if (songName == null) continue;

          final artistNames = (song['singer'] as List? ?? [])
              .map((ar) => (ar as Map?)?['name']?.toString() ?? '')
              .toList();

          final durationMs = (song['interval'] as int? ?? 0) * 1000;

          genericSongs.add(
            GenericSong(
              data: song,
              title: songName,
              artist: artistNames,
              durationMs: durationMs,
            ),
          );
        }

        // order the songs by similarity
        final orderedSongs = SongResultHelper.orderBySimilarity(
          genericSongs,
          title,
          artist,
          durationSeconds * 1000,
          5000,
        );

        if (orderedSongs.isEmpty) {
          debugPrint(
            '[QQMusic] Search returned songs but none matched the similarity threshold or length differ too large',
          );
          continue;
        }

        return orderedSongs;
      }
      return [];
    } catch (e) {
      debugPrint('[QQMusic] Error searching song: $e');
      return [];
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
