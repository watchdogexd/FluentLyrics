import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/string_similarity.dart';

class NeteaseService {
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

      onStatusUpdate?.call('[NeteaseMusic] Fetching lyrics...');
      final lyricData = await _getLyrics(songId, trimMetadata);

      if (lyricData == null) {
        return LyricsResult.empty();
      }

      return lyricData.copyWith(artworkUrl: artworkUrl);
    } catch (e) {
      debugPrint('[NeteaseMusic] Error fetching lyrics: $e');
    }
    return LyricsResult.empty();
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data,
  ) async {
    try {
      final lyricData = await fetchLyrics(
        title: data.title,
        artist: data.artist,
        album: data.album,
        durationSeconds: data.durationSeconds,
      );

      if (lyricData.subLyrics == null) {
        return LyricsResult.empty();
      } else {
        return lyricData.subLyrics!;
      }
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
      const eapiSearchUrl =
          'https://interface.music.163.com/eapi/cloudsearch/pc';

      final now = DateTime.now().toUtc();
      final buildver = (now.millisecondsSinceEpoch ~/ 1000).toString();
      final requestId =
          '${now.millisecondsSinceEpoch}_${Random().nextInt(1000).toString().padLeft(4, '0')}';

      final eapiHeader = {
        '__csrf': '',
        'appver': '8.0.0',
        'buildver': buildver,
        'channel': '',
        'deviceId': '',
        'mobilename': '',
        'resolution': '1920x1080',
        'os': 'android',
        'osver': '',
        'requestId': requestId,
        'versioncode': '140',
        'MUSIC_U': '',
      };

      final eapiData = {
        's': keyword,
        'type': '1', // Single song
        'limit': '20',
        'offset': '0',
        'total': 'true',
        'header': jsonEncode(eapiHeader),
      };

      final encrypted = _NeteaseEapiHelper.encrypt(eapiSearchUrl, eapiData);
      final headers = _NeteaseEapiHelper.buildHeaders(eapiHeader);

      final searchResponse = await http
          .post(Uri.parse(eapiSearchUrl), headers: headers, body: encrypted)
          .timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        debugPrint(
          '[NeteaseMusic] Search failed: ${searchResponse.statusCode}',
        );
        return null;
      }

      final searchData = jsonDecode(searchResponse.body);
      if (searchData['code'] != 200) {
        debugPrint(
          '[NeteaseMusic] Search returned unexpected code: ${searchData['code']}',
        );
        return null;
      }

      final result = searchData['result'];
      if (result == null ||
          (result['songs'] == null && result['songCount'] == 0)) {
        return null;
      }

      final songs = result['songs'] as List? ?? [];
      if (songs.isEmpty) {
        return null;
      }

      // Filter based on similarity
      final filteredSongs = songs.where((song) {
        final songName = song['name'] as String?;
        if (songName == null) return false;

        final similarity = StringSimilarity.getJaroWinklerScore(
          title.toLowerCase(),
          songName.toLowerCase(),
        );
        return similarity >= 0.7;
      }).toList();

      if (filteredSongs.isEmpty) {
        debugPrint(
          '[NeteaseMusic] search returned songs but none matched the title similarity threshold',
        );
        return null;
      }

      // Select best match
      dynamic bestMatch = filteredSongs[0];
      double minDiff = 1000000;

      for (var song in filteredSongs) {
        final songDurationMs = song['duration'] ?? song['dt'];
        if (songDurationMs != null) {
          final diff = (songDurationMs / 1000 - durationSeconds)
              .abs()
              .toDouble();
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

      return bestMatch;
    } catch (e) {
      debugPrint('[NeteaseMusic] Error searching song: $e');
      return null;
    }
  }

  Future<LyricsResult?> _getLyrics(String songId, bool trimMetadata) async {
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
        List<Lyric> lyrics = [];
        Map<String, String> trimmedMetadata = {};

        if (yrc != null && yrc.isNotEmpty) {
          lyrics = NeteaseYrcParser.parse(yrc);
          if (trimMetadata) {
            final trimResult = LrcParser.trimMetadataLines(lyrics);
            lyrics = trimResult.lyrics;
            trimmedMetadata = trimResult.trimmedMetadata;
          }
        }

        if (lyrics.isEmpty && lrc != null && lrc.isNotEmpty) {
          final parseResult = LrcParser.parse(lrc, trimMetadata: trimMetadata);
          lyrics = parseResult.lyrics;
          trimmedMetadata = parseResult.trimmedMetadata;
        }

        // Parse translation
        LyricsResult? subLyrics;
        if (tlyric != null && tlyric.isNotEmpty) {
          final transParse = LrcParser.parse(tlyric);
          if (transParse.lyrics.isNotEmpty) {
            subLyrics = LyricsResult(
              lyrics: transParse.lyrics,
              source: 'Netease Music',
              isSynced: true,
              language: 'zh',
              translation: true,
              translationProvider: 'Netease Music',
              translationContributor: translationContributor,
            );
          }
        }

        return LyricsResult(
          lyrics: lyrics,
          source: 'Netease Music',
          contributor: lyricContributor,
          writtenBy: trimmedMetadata['作词'] ?? trimmedMetadata['作詞'],
          composer: trimmedMetadata['作曲'],
          isPureMusic: isPureMusic,
          subLyrics: subLyrics,
        );
      } else {
        debugPrint('[NeteaseMusic] returned no lyrics for songId: $songId');
        return null;
      }
    } catch (e, s) {
      debugPrint('[NeteaseMusic] Error fetching lyrics JSON: $e\n$s');
      return null;
    }
  }
}

class _NeteaseEapiHelper {
  static const String _eapiKey = 'e82ckenh8dichen8';
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 9; PCT-AL10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.64 HuaweiBrowser/10.0.3.311 Mobile Safari/537.36';

  static Map<String, String> buildHeaders(Map<String, String> cookieData) {
    final cookie = cookieData.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    return {
      'User-Agent': _userAgent,
      'Referer': 'https://music.163.com/',
      'Cookie': cookie,
    };
  }

  static Map<String, String> encrypt(String url, Map<String, dynamic> data) {
    final path = url
        .replaceAll('https://interface3.music.163.com/e', '/')
        .replaceAll('https://interface.music.163.com/e', '/');

    final text = jsonEncode(data);
    final message = 'nobody${path}use${text}md5forencrypt';
    final digest = md5.convert(utf8.encode(message)).toString();

    final payload = '$path-36cd479b6b5-$text-36cd479b6b5-$digest';

    final key = encrypt_pkg.Key.fromUtf8(_eapiKey);
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.ecb, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encrypt(payload);

    return {
      'params': encrypted.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(),
    };
  }
}
