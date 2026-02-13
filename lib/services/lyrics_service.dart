import '../models/lyric_model.dart';
import '../models/lyric_provider_type.dart';
import '../models/general_translation_request_data.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';
import 'providers/lrclib_service.dart';
import 'providers/musixmatch_service.dart';
import 'providers/netease_service.dart';
import 'providers/qqmusic_service.dart';
import 'providers/lyrics_cache_service.dart';

class LyricsService {
  final SettingsService _settingsService = SettingsService();
  // lyrics providers
  final LrclibService _lrclibService = LrclibService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final NeteaseService _neteaseService = NeteaseService();
  final QQMusicService _qqMusicService = QQMusicService();
  final LyricsCacheService _cacheService = LyricsCacheService();

  Stream<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool Function()? isCancelled,
    required List<LyricProviderType> trimMetadataProviders,
    required bool richSyncEnabled,
    bool translationEnabled = true,
  }) async* {
    final priority = await _settingsService.getPriority();
    final cacheEnabledSetting = await _settingsService.getCacheEnabled();
    final cacheEnabled = cacheEnabledSetting.current;

    // Translation settings
    final targetLanguages =
        (await _settingsService.getTranslationTargetLanguages()).current;
    final ignoredLanguages =
        (await _settingsService.getTranslationIgnoredLanguages()).current;
    final translationBias =
        (await _settingsService.getTranslationBias()).current;

    // Always prioritize cache first
    final fullPriority = [LyricProviderType.cache, ...priority];

    LyricsResult? bestResult;

    for (var provider in fullPriority) {
      if (isCancelled?.call() == true) {
        if (bestResult != null) yield bestResult;
        return;
      }

      LyricsResult result = LyricsResult.empty();
      final shouldTrimMetadata = trimMetadataProviders.contains(provider);

      if (provider == LyricProviderType.cache) {
        result = await _cacheService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
        );
      } else if (provider == LyricProviderType.lrclib) {
        result = await _lrclibService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
        );
      } else if (provider == LyricProviderType.musixmatch) {
        result = await _musixmatchService.fetchLyrics(
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
        );
      } else if (provider == LyricProviderType.netease) {
        result = await _neteaseService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
          trimMetadata: shouldTrimMetadata,
        );
      } else if (provider == LyricProviderType.qqmusic) {
        result = await _qqMusicService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
          trimMetadata: shouldTrimMetadata,
        );
      }

      if (result.lyrics.isNotEmpty ||
          result.artworkUrl != null ||
          result.isPureMusic) {
        // Cache the raw result from other providers
        if (cacheEnabled && provider != LyricProviderType.cache) {
          await _cacheService.cacheLyrics(
            title,
            artist,
            album,
            durationSeconds,
            result,
          );
        }

        if (bestResult == null) {
          bestResult = result;
        } else {
          // If the new result has lyrics/pureMusic and the current best doesn't,
          // or if the new one is synced and old isn't.
          bool newBetter = false;
          if (result.isPureMusic && !bestResult.isPureMusic) {
            newBetter = true;
          } else if (result.lyrics.isNotEmpty && bestResult.lyrics.isEmpty) {
            newBetter = true;
          } else if (result.lyrics.isNotEmpty &&
              result.isRichSync &&
              richSyncEnabled &&
              !bestResult.isRichSync) {
            newBetter = true;
          } else if (result.lyrics.isNotEmpty &&
              result.isSynced &&
              !bestResult.isSynced) {
            newBetter = true;
          }
          // New: Check for translation (subLyrics)
          else if (result.subLyrics != null && bestResult.subLyrics == null) {
            // If we prefer translation, maybe this is better?
            // But valid lyrics are more important.
            // If both have lyrics, and this one has translation, usage depends.
            // Let's assume if qualities are equal, one with translation is better.
            if (result.isSynced == bestResult.isSynced &&
                result.isRichSync == bestResult.isRichSync) {
              newBetter = true;
            }
          }

          if (newBetter) {
            bestResult = result.copyWith(
              lyrics: result.lyrics,
              source: result.source,
              isSynced: result.isSynced,
              writtenBy: result.writtenBy,
              composer: result.composer,
              contributor: result.contributor,
              copyright: result.copyright,
              artworkUrl: result.artworkUrl ?? bestResult.artworkUrl,
              isPureMusic: result.isPureMusic,
              subLyrics: result.subLyrics, // Copy subLyrics
            );
          } else {
            // Keep existing lyrics, but take artwork if missing.
            if (bestResult.artworkUrl == null && result.artworkUrl != null) {
              bestResult = bestResult.copyWith(artworkUrl: result.artworkUrl);
            }
          }
        }

        // Yield intermediate best result (without translation merge yet, or maybe merge if subLyrics exists?)
        // If we yield here, UI sees it.
        // We should merge if we can.
        if (translationEnabled && targetLanguages.isNotEmpty) {
          yield _processTranslation(bestResult, translationBias);
        } else {
          yield bestResult;
        }
      }

      // If we have (rich sync lyrics OR pure music) AND artwork, we can stop early.
      // But we might want to wait for translation?
      // "wait for the 'best lyric result', and move on to try those fetchTranslations method"
      // If we stop early, we might miss translation.
      // We should only stop early if we are satisfied.
      // If targetLanguages is set, and we don't have translation, maybe don't stop?
      // But prompt says "if the provider returns the translation within fetchLyrics... if no, wait for the 'best lyric result', and move on..."
      // This implies we finish the loop for lyrics first.

      if (bestResult != null &&
          (bestResult.isPureMusic ||
              (bestResult.lyrics.isNotEmpty &&
                  ((bestResult.isRichSync && richSyncEnabled) ||
                      (!richSyncEnabled && bestResult.isSynced)))) &&
          bestResult.artworkUrl != null) {
        // Good enough lyrics. But do we have translation?
        if (translationEnabled &&
            targetLanguages.isNotEmpty &&
            bestResult.subLyrics == null) {
          // Continue searching to see if other providers have translation (via fetchLyrics returning subLyrics)
          // or just break and fall into fetchTranslation phase.
          // If we already checked high priority providers...
          // Let's break and try fetchTranslation.
          break;
        } else {
          // We have translation or don't want it.
          break;
        }
      }
    }

    // Post-loop translation fetching
    if (translationEnabled &&
        bestResult != null &&
        targetLanguages.isNotEmpty &&
        bestResult.subLyrics == null &&
        bestResult.lyrics.isNotEmpty &&
        (bestResult.language == null ||
            !ignoredLanguages.contains(bestResult.language))) {
      // Prepare request
      final requestData = GeneralTranslationRequestData(
        title: title,
        artist: artist,
        content: bestResult.lyrics.map((l) => l.text).join('\n'),
      );

      // Iterate translation providers
      for (var targetLanguage in targetLanguages) {
        LyricsResult? transResult;
        for (var tProvider in priority) {
          if (tProvider == LyricProviderType.netease &&
              _neteaseService.checkTranslationSupport(targetLanguage)) {
            transResult = await _neteaseService.fetchTranslation(requestData);
          } else if (tProvider == LyricProviderType.qqmusic &&
              _qqMusicService.checkTranslationSupport(targetLanguage)) {
            transResult = await _qqMusicService.fetchTranslation(requestData);
          } else if (tProvider == LyricProviderType.musixmatch &&
              _musixmatchService.checkTranslationSupport(targetLanguage)) {
            transResult = await _musixmatchService.fetchTranslation(
              requestData,
              targetLanguage,
            );
          } else {
            debugPrint('Unsupported translation provider: $tProvider');
            continue;
          }
          // Add other providers here if they support fetchTranslation

          if (!transResult.translation) {
            debugPrint('Failed to fetch translation from $tProvider');
            transResult = null;
            continue;
          }
        }
        if (transResult != null && transResult.translation) {
          // Update bestResult with new translation
          bestResult = bestResult!.copyWith(subLyrics: transResult);
          yield _processTranslation(bestResult, translationBias);
          break;
        }
      }
    }
  }

  LyricsResult _processTranslation(LyricsResult result, int bias) {
    if (result.subLyrics != null) {
      return _mergeLyrics(result, result.subLyrics!, bias);
    }
    return result;
  }

  LyricsResult _mergeLyrics(
    LyricsResult original,
    LyricsResult translation,
    int biasMs,
  ) {
    if (original.lyrics.isEmpty || translation.lyrics.isEmpty) return original;

    final mergedLyrics = original.lyrics.map((lyric) {
      Lyric? bestMatch;
      int minDiff = 2000; // 2s window

      for (var transLyric in translation.lyrics) {
        final transTime = transLyric.startTime.inMilliseconds + biasMs;
        final diff = (lyric.startTime.inMilliseconds - transTime).abs();

        if (diff < minDiff) {
          minDiff = diff;
          bestMatch = transLyric;
        }
      }

      if (bestMatch != null) {
        return Lyric(
          startTime: lyric.startTime,
          endTime: lyric.endTime,
          text: lyric.text,
          inlineParts: lyric.inlineParts,
          translation: bestMatch.text,
        );
      }
      return lyric;
    }).toList();

    return original.copyWith(
      lyrics: mergedLyrics,
      translationProvider: translation.source,
      translationContributor: translation.contributor,
    );
  }
}
