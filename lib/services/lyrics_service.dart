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
import 'providers/llm_translation_service.dart';

class LyricsService {
  final SettingsService _settingsService = SettingsService();
  // lyrics providers
  final LrclibService _lrclibService = LrclibService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final NeteaseService _neteaseService = NeteaseService();
  final QQMusicService _qqMusicService = QQMusicService();
  final LlmTranslationService _llmService = LlmTranslationService(
    SettingsService(),
  );
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
    Function(String)? onArtworkUrl,
    Function(LyricsResult)? onTranslation,
  }) async* {
    final priority = await _settingsService.getPriority();
    final cacheEnabledSetting = await _settingsService.getCacheEnabled();
    final cacheEnabled = cacheEnabledSetting.current;

    final translationBias =
        (await _settingsService.getTranslationBias()).current;
    final useStandardLyricsForPairing =
        (await _settingsService.getUseStandardLyricsForPairingProviders())
            .current;

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
          onArtworkUrl: onArtworkUrl,
        );
      } else if (provider == LyricProviderType.netease) {
        result = await _neteaseService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
          trimMetadata: shouldTrimMetadata,
          translationBias: translationBias,
          useStandardLyricsForPairing: useStandardLyricsForPairing.contains(
            LyricProviderType.netease,
          ),
          onTranslation: onTranslation,
        );
      } else if (provider == LyricProviderType.qqmusic) {
        result = await _qqMusicService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
          trimMetadata: shouldTrimMetadata,
          translationBias: translationBias,
          useStandardLyricsForPairing: useStandardLyricsForPairing.contains(
            LyricProviderType.qqmusic,
          ),
          onTranslation: onTranslation,
        );
      }

      if (result.lyrics.isNotEmpty || result.isPureMusic) {
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

          if (newBetter) {
            bestResult = result.copyWith(
              lyrics: result.lyrics,
              source: result.source,
              isSynced: result.isSynced,
              writtenBy: result.writtenBy,
              composer: result.composer,
              contributor: result.contributor,
              copyright: result.copyright,
              isPureMusic: result.isPureMusic,
            );
          }
        }

        // Yield intermediate best result (without translation merge yet, or maybe merge if subLyrics exists?)
        // If we yield here, UI sees it.
        // We should merge if we can.
        yield bestResult;
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
                      (!richSyncEnabled && bestResult.isSynced))))) {
        break;
      }
    }
  }

  Stream<LyricsResult> fetchTranslation({
    required LyricsResult bestResult,
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    bool Function()? isCancelled,
  }) async* {
    final cacheEnabledSetting = await _settingsService.getCacheEnabled();
    final cacheEnabled = cacheEnabledSetting.current;

    final targetLanguages =
        (await _settingsService.getTranslationTargetLanguages()).current;
    final ignoredLanguages =
        (await _settingsService.getTranslationIgnoredLanguages()).current;
    final translationBias =
        (await _settingsService.getTranslationBias()).current;
    final useStandardLyricsForPairing =
        (await _settingsService.getUseStandardLyricsForPairingProviders())
            .current;
    final priority = await _settingsService.getPriority();
    final fullPriority = [LyricProviderType.cache, ...priority];

    if (targetLanguages.isEmpty ||
        bestResult.lyrics.isEmpty ||
        (bestResult.language != null &&
            ignoredLanguages.contains(bestResult.language))) {
      return;
    }
      // Prepare request with LRC formatted content to preserve timestamps for LLM
      final requestData = GeneralTranslationRequestData(
        title: title,
        artist: artist,
        album: album,
        durationSeconds: durationSeconds,
        content: bestResult.lyrics
            .map((l) {
              final m = l.startTime.inMinutes
                  .remainder(60)
                  .toString()
                  .padLeft(2, '0');
              final s = l.startTime.inSeconds
                  .remainder(60)
                  .toString()
                  .padLeft(2, '0');
              final ms = (l.startTime.inMilliseconds % 1000 ~/ 10)
                  .toString()
                  .padLeft(2, '0');
              return '[$m:$s.$ms]${l.text}';
            })
            .join('\n'),
      );

      // check if source == target
      if (bestResult.language != null &&
          targetLanguages.contains(bestResult.language)) {
        debugPrint(
          'Target language contains source language, skipping translation',
        );
        return;
      }
      // Iterate translation providers
      for (var targetLanguage in targetLanguages) {
        LyricsResult? transResult;
        bool cachedResult = false;
        debugPrint('Checking translation providers for $targetLanguage');
        for (var tProvider in fullPriority) {
          if (isCancelled?.call() == true) return;
          if (tProvider == LyricProviderType.cache && cacheEnabled) {
            debugPrint('Checking cache for translation');
            final cacheId = _cacheService.generateTranslationCacheId(
              title,
              artist,
              targetLanguage,
            );
            transResult = await _cacheService.getCachedTranslation(cacheId);
            if (transResult != null) {
              cachedResult = true;
              transResult = transResult.copyWith(
                translationProvider:
                    '${transResult.translationProvider} (cached)',
              );
            }
          } else if (tProvider == LyricProviderType.netease) {
            if (!_neteaseService.checkTranslationSupport(targetLanguage)) {
              continue;
            }
            debugPrint('Fetching translation from Netease');
            transResult = await _neteaseService.fetchTranslation(
              requestData,
              translationBias: translationBias,
              useStandardLyricsForPairing: useStandardLyricsForPairing.contains(
                LyricProviderType.netease,
              ),
            );
          } else if (tProvider == LyricProviderType.qqmusic) {
            if (!_qqMusicService.checkTranslationSupport(targetLanguage)) {
              continue;
            }
            debugPrint('Fetching translation from QQMusic');
            transResult = await _qqMusicService.fetchTranslation(
              requestData,
              translationBias: translationBias,
              useStandardLyricsForPairing: useStandardLyricsForPairing.contains(
                LyricProviderType.qqmusic,
              ),
            );
          } else if (tProvider == LyricProviderType.musixmatch) {
            if (!_musixmatchService.checkTranslationSupport(targetLanguage)) {
              continue;
            }
            debugPrint('Fetching translation from Musixmatch');
            transResult = await _musixmatchService.fetchTranslation(
              requestData,
              targetLanguage,
            );
          } else if (tProvider == LyricProviderType.llm) {
            if (!_llmService.checkTranslationSupport(targetLanguage)) {
              continue;
            }
            debugPrint('Fetching translation from LLM');
            transResult = await _llmService.fetchTranslation(
              requestData,
              targetLanguage,
            );
          } else {
            debugPrint('Unsupported translation provider: $tProvider');
            continue;
          }

          if (transResult == null ||
              !(transResult.translation || transResult.source == 'SKIPPED')) {
            debugPrint('Failed to fetch translation from $tProvider');
            transResult = null;
            continue;
          } else if (!cachedResult) {
            // New translation found, cache it if enabled
            debugPrint('New translation received');
            if (cacheEnabled &&
                tProvider != LyricProviderType.cache &&
                (transResult.translation || transResult.source == 'SKIPPED')) {
              debugPrint('Caching translation');
              final cacheId = _cacheService.generateTranslationCacheId(
                title,
                artist,
                targetLanguage,
              );
              await _cacheService.cacheTranslation(cacheId, transResult);
            }
            break;
          } else if (cachedResult) {
            // translation is cached, break
            break;
          } else {
            // wut
          }
        }
        if (transResult != null && transResult.translation) {
          yield transResult;
          break;
        } else if (transResult != null && transResult.source == 'SKIPPED') {
          debugPrint('Translation skipped by provider');
          break;
        }
      }
  }
}
