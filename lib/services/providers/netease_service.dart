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
    return language == 'zh';
  }

  static const String _lyricUrl = 'https://music.163.com/api/song/lyric';
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
        debugPrint('Netease search failed: ${searchResponse.statusCode}');
        return null;
      }

      final searchData = jsonDecode(searchResponse.body);
      if (searchData['code'] != 200) {
        debugPrint(
          'Netease search returned unexpected code: ${searchData['code']}',
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
      debugPrint('Error searching song on Netease: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLyricJson(String songId) async {
    try {
      final lyricUri = Uri.parse(_lyricUrl).replace(
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

      return jsonDecode(lyricResponse.body);
    } catch (e) {
      debugPrint('Error fetching lyrics JSON from Netease: $e');
      return null;
    }
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
      onStatusUpdate?.call('Searching lyrics on Netease...');
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

      onStatusUpdate?.call('Fetching lyrics from Netease...');
      final lyricData = await _fetchLyricJson(songId);

      if (lyricData == null) {
        return LyricsResult.empty();
      }

      final String? lrc = lyricData['lrc']?['lyric'];
      final String? yrc = lyricData['yrc']?['lyric'];
      final String? tlyric = lyricData['tlyric']?['lyric'];
      final bool isPureMusic = lyricData['pureMusic'] == true;

      String? contributor;
      final lyricUser = lyricData['lyricUser'];
      if (lyricUser != null && lyricUser['nickname'] != null) {
        contributor = lyricUser['nickname'];
      }

      final transUser = lyricData['transUser'];
      if (transUser != null && transUser['nickname'] != null) {
        if (contributor != null) {
          contributor += " & ${transUser['nickname']}";
        } else {
          contributor = transUser['nickname'];
        }
      }

      if ((lrc != null && lrc.isNotEmpty) ||
          (yrc != null && yrc.isNotEmpty) ||
          (tlyric != null && tlyric.isNotEmpty) ||
          artworkUrl != null ||
          isPureMusic) {
        onStatusUpdate?.call('Processing lyrics...');

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
              translation: true,
            );
          }
        }

        return LyricsResult(
          lyrics: lyrics,
          source: 'Netease Music',
          contributor: contributor,
          artworkUrl: artworkUrl,
          writtenBy: trimmedMetadata['作词'] ?? trimmedMetadata['作詞'],
          composer: trimmedMetadata['作曲'],
          isPureMusic: isPureMusic,
          subLyrics: subLyrics,
        );
      } else {
        debugPrint('Netease returned no lyrics or artwork for songId: $songId');
      }
    } catch (e) {
      debugPrint('Error fetching lyrics from Netease: $e');
    }
    return LyricsResult.empty();
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data,
  ) async {
    try {
      // Search with duration 0 as request data lacks it
      final bestMatch = await _searchSong(
        title: data.title,
        artist: data.artist,
        durationSeconds: 0,
      );

      if (bestMatch == null) return LyricsResult.empty();

      final songId = bestMatch['id'].toString();
      final lyricData = await _fetchLyricJson(songId);

      if (lyricData == null) return LyricsResult.empty();

      final String? tlyric = lyricData['tlyric']?['lyric'];
      if (tlyric != null && tlyric.isNotEmpty) {
        final parse = LrcParser.parse(tlyric);
        if (parse.lyrics.isNotEmpty) {
          return LyricsResult(
            lyrics: parse.lyrics,
            source: 'Netease Music',
            translation: true,
            isSynced: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching translation from Netease: $e');
    }
    return LyricsResult.empty();
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
