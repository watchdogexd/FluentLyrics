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
    int translationBias = 0,
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
      final lyricData = await _getLyrics(songId, trimMetadata, translationBias);

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
    GeneralTranslationRequestData data, {
    int translationBias = 0,
  }) async {
    try {
      final lyricData = await fetchLyrics(
        title: data.title,
        artist: data.artist,
        album: data.album,
        durationSeconds: data.durationSeconds,
        translationBias: translationBias,
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

        final similarity = StringSimilarity.getJaroWinklerScore(
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
          final diff = (songDuration - (durationSeconds * 1000)).abs().toDouble();
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
            final List<Map<String, String>> rawTranslation = [];
            // Try to pair with original lyrics based on timestamps + bias
            for (var transLine in transParse.lyrics) {
              final adjustedTransTime =
                  transLine.startTime.inMilliseconds + translationBias;

              // Find matching original line (closest within 2s)
              Lyric? bestMatch;
              int minAbsDiff = 2000;

              for (var l in lyrics) {
                final diff = (l.startTime.inMilliseconds - adjustedTransTime).abs();
                if (diff < minAbsDiff) {
                  minAbsDiff = diff.toInt();
                  bestMatch = l;
                }
              }

              if (bestMatch != null && bestMatch.text.isNotEmpty) {
                rawTranslation.add({
                  'original': bestMatch.text,
                  'translated': transLine.text,
                });
              }
            }

            subLyrics = LyricsResult(
              lyrics: [],
              rawTranslation: rawTranslation,
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
          isPureMusic: isPureMusic,
          contributor: lyricContributor,
          subLyrics: subLyrics,
          metadata: trimmedMetadata,
        );
      }
    } catch (e) {
      debugPrint('[NeteaseMusic] Error fetching lyrics: $e');
    }
    return null;
  }
}

class NeteaseYrcParser {
  static List<Lyric> parse(String text) {
    final List<Lyric> lyrics = [];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        // [123,456]text or [123,456](0,0,0)text
        final match = RegExp(r'^\[(\d+),(\d+)\](.*)$').firstMatch(line);
        if (match != null) {
          final startMs = int.parse(match.group(1)!);
          final durationMs = int.parse(match.group(2)!);
          final content = match.group(3)!;

          // Parse inline parts if available
          final List<LyricInlinePart> inlineParts = [];
          final partMatches =
              RegExp(r'\((\d+),(\d+),(\d+)\)([^\(\[]*)').allMatches(content);

          String plainText = '';
          if (partMatches.isNotEmpty) {
            for (var pm in partMatches) {
              final pStartOffset = int.parse(pm.group(1)!);
              final pDuration = int.parse(pm.group(2)!);
              final pText = pm.group(4)!;
              
              inlineParts.add(
                LyricInlinePart(
                  startTime: Duration(milliseconds: startMs + pStartOffset),
                  endTime: Duration(
                    milliseconds: startMs + pStartOffset + pDuration,
                  ),
                  text: pText,
                ),
              );
              plainText += pText;
            }
          } else {
            plainText = content.replaceAll(RegExp(r'\(.*\)'), '');
          }

          lyrics.add(
            Lyric(
              startTime: Duration(milliseconds: startMs),
              endTime: Duration(milliseconds: startMs + durationMs),
              text: plainText,
              inlineParts: inlineParts.isNotEmpty ? inlineParts : null,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error parsing Netease YRC line: $line - $e');
      }
    }

    return lyrics;
  }
}
