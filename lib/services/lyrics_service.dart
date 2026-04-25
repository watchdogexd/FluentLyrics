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
    required List<String> artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    Function(bool)? onFetchStatusUpdate,
    bool Function()? isCancelled,
    required List<LyricProviderType> trimMetadataProviders,
    required bool richSyncEnabled,
    Function(LyricsResult)? onTranslation,

    /// Called for every provider result that has lyrics (not only the current best).
    void Function(LyricsResult)? onCandidate,

    /// Called once when we would normally break early (good-enough result found).
    /// Awaited: return true to continue fetching remaining providers, false to stop.
    Future<bool> Function()? onPauseForCandidates,
  }) async* {
    debugPrint(
      '[LyricsService.fetchLyrics] Fetching lyrics for $title - ${artist.join(', ')}',
    );
    final priority = await _settingsService.getPriority();
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;
    final translationEnabled =
        (await _settingsService.getTranslationEnabled()).current;

    final translationBias =
        (await _settingsService.getTranslationBias()).current;

    // create a on translation wrapper that change translationReceived if called
    bool translationReceived = false;
    LyricsResult onTranslationWrapper(LyricsResult result) {
      if (translationEnabled &&
          result.translation &&
          result.rawTranslation!.isNotEmpty) {
        translationReceived = true;
        onTranslation?.call(result);
      }
      return result;
    }

    LyricsResult? bestResult;
    for (var provider in priority) {
      debugPrint('[LyricsService.fetchLyrics]   ==> Fetching from $provider');
      if (isCancelled?.call() == true) {
        if (bestResult != null) yield bestResult;
        return;
      }

      LyricsResult result = LyricsResult.empty();
      final shouldTrimMetadata = trimMetadataProviders.contains(provider);
      List<String> accumulatedArtworkUrls = [];

      void onArtworkUrl(String url) {
        if (url.isNotEmpty && !accumulatedArtworkUrls.contains(url)) {
          debugPrint(
            '[LyricsService.fetchLyrics]     ==> Received new artwork url: $url',
          );
          accumulatedArtworkUrls.add(url);
        }
      }

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
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
          onArtworkUrl: onArtworkUrl,
          trimMetadata: shouldTrimMetadata,
          translationBias: translationBias,
          onTranslation: onTranslationWrapper,
        );
      } else if (provider == LyricProviderType.qqmusic) {
        result = await _qqMusicService.fetchLyrics(
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          onArtworkUrl: onArtworkUrl,
          onStatusUpdate: onStatusUpdate,
          trimMetadata: shouldTrimMetadata,
          translationBias: translationBias,
          onTranslation: onTranslationWrapper,
        );
      }

      if (accumulatedArtworkUrls.isNotEmpty) {
        result = result.copyWith(artworkUrls: accumulatedArtworkUrls);
      }

      if (result.lyrics.isNotEmpty || result.isPureMusic) {
        // Report every provider result as a candidate (not just the best).
        onCandidate?.call(result);

        bool newBetter = false;
        if (bestResult == null) {
          // this is the first valid result
          newBetter = true;
        } else if (result.isPureMusic && !bestResult.isPureMusic) {
          // new is pure music, old is not
          newBetter = false;
        } else if (result.lyrics.isNotEmpty && bestResult.lyrics.isEmpty) {
          // new has lyrics, old does not
          newBetter = true;
        } else if (result.lyrics.isNotEmpty &&
            result.isRichSync &&
            richSyncEnabled &&
            !bestResult.isRichSync) {
          // new is rich sync, old is not
          newBetter = true;
        } else if (result.lyrics.isNotEmpty &&
            result.isSynced &&
            !bestResult.isSynced) {
          // new is synced, old is not
          newBetter = true;
        } else if ((result.artworkUrls?.length ?? 0) >
            (bestResult.artworkUrls?.length ?? 0)) {
          // new have more artwork urls, old does not
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
            artworkUrls: result.artworkUrls,
          );

          debugPrint(
            '[LyricsService.fetchLyrics]     ==> Yielding new best result',
          );
          yield bestResult;

          // Cached? break
          if (provider == LyricProviderType.cache) {
            debugPrint(
              '[LyricsService.fetchLyrics]     ==> This LyricsResult is cached, breaking loop',
            );
            break;
          }
          // Cache the raw result from other providers
          if (cacheEnabled &&
              provider != LyricProviderType.cache &&
              (bestResult.lyrics.isNotEmpty || bestResult.isPureMusic)) {
            await _cacheService
                .cacheLyrics(title, artist, album, durationSeconds, bestResult)
                .then((_) {
                  debugPrint(
                    '[LyricsService.fetchLyrics]     ==> newBetter lyrics cached',
                  );
                });
          }
        }
      }

      // Early-exit when we already have a high-quality result.
      // If onPauseForCandidates is provided, pause here (once) so the user can
      // open the candidates panel; resolving true continues remaining providers.
      final bool isGoodEnough =
          bestResult != null &&
          (bestResult.isPureMusic ||
              (bestResult.lyrics.isNotEmpty &&
                  ((bestResult.isRichSync && richSyncEnabled) ||
                      (!richSyncEnabled && bestResult.isSynced)))) &&
          ((translationEnabled && translationReceived) || !translationEnabled);

      if (isGoodEnough) {
        if (onPauseForCandidates != null) {
          debugPrint(
            '[LyricsService.fetchLyrics]     ==> Good result found; pausing for candidate selection',
          );
          onFetchStatusUpdate?.call(false);
          final shouldContinue = await onPauseForCandidates();
          // Only pause once; clear callback effect by treating this as done.
          onPauseForCandidates = null;
          onFetchStatusUpdate?.call(true);
          if (!shouldContinue) {
            break;
          }
          debugPrint(
            '[LyricsService.fetchLyrics]     ==> Resuming fetch for remaining providers',
          );
        } else {
          break;
        }
      }
    }
    onFetchStatusUpdate?.call(false);
  }

  Stream<LyricsResult> fetchTranslation({
    required LyricsResult bestResult,
    required String title,
    required List<String> artist,
    required String album,
    required int durationSeconds,
    bool Function()? isCancelled,

    /// Called for every provider that returns a valid translation (not just the
    /// first winner). Used to populate the translation candidate list.
    void Function(LyricsResult)? onTranslationCandidate,
  }) async* {
    debugPrint(
      '[LyricsService.fetchTranslation] Fetching translation for $title - ${artist.join(', ')}',
    );
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;

    final targetLanguages =
        (await _settingsService.getTranslationTargetLanguages()).current;
    final ignoredLanguages =
        (await _settingsService.getTranslationIgnoredLanguages()).current;
    final translationBias =
        (await _settingsService.getTranslationBias()).current;
    final priority = await _settingsService.getPriority();

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
        '[LyricsService.fetchTranslation]   ==> Target language contains source language, skipping translation',
      );
      return;
    }

    LyricsResult? firstYielded;

    // Iterate translation providers
    for (var targetLanguage in targetLanguages) {
      LyricsResult? transResult;
      bool cachedResult = false;
      debugPrint(
        '[LyricsService.fetchTranslation]   ==> Checking providers for $targetLanguage',
      );
      for (var tProvider in priority) {
        if (isCancelled?.call() == true) return;
        if (tProvider == LyricProviderType.cache && cacheEnabled) {
          debugPrint('[LyricsService.fetchTranslation]     ==> Checking cache');
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
          debugPrint(
            '[LyricsService.fetchTranslation]     ==> Fetching from Netease',
          );
          transResult = await _neteaseService.fetchTranslation(
            requestData,
            translationBias: translationBias,
          );
        } else if (tProvider == LyricProviderType.qqmusic) {
          if (!_qqMusicService.checkTranslationSupport(targetLanguage)) {
            continue;
          }
          debugPrint(
            '[LyricsService.fetchTranslation]     ==> Fetching from QQMusic',
          );
          transResult = await _qqMusicService.fetchTranslation(
            requestData,
            translationBias: translationBias,
          );
        } else if (tProvider == LyricProviderType.musixmatch) {
          if (!_musixmatchService.checkTranslationSupport(targetLanguage)) {
            continue;
          }
          debugPrint(
            '[LyricsService.fetchTranslation]     ==> Fetching from Musixmatch',
          );
          transResult = await _musixmatchService.fetchTranslation(
            requestData,
            targetLanguage,
          );
        } else if (tProvider == LyricProviderType.llm) {
          if (!_llmService.checkTranslationSupport(targetLanguage)) {
            continue;
          }
          debugPrint(
            '[LyricsService.fetchTranslation]     ==> Fetching from LLM',
          );
          transResult = await _llmService.fetchTranslation(
            requestData,
            targetLanguage,
          );
        } else {
          debugPrint(
            '[LyricsService.fetchTranslation]     ==> [!] Unsupported provider: $tProvider',
          );
          continue;
        }

        if (transResult == null ||
            !(transResult.translation || transResult.source == 'SKIPPED')) {
          debugPrint('[LyricsService.fetchTranslation]       ==> [!] Failed');
          transResult = null;
          continue;
        }

        // Report as a candidate regardless of cache/first status.
        if (transResult.translation) {
          onTranslationCandidate?.call(transResult);
        }

        if (!cachedResult) {
          // New translation found, cache it if enabled
          debugPrint(
            '[LyricsService.fetchTranslation]       ==> New translation received',
          );
          if (cacheEnabled &&
              tProvider != LyricProviderType.cache &&
              (transResult.translation || transResult.source == 'SKIPPED')) {
            debugPrint(
              '[LyricsService.fetchTranslation]         ==> Caching translation',
            );
            final cacheId = _cacheService.generateTranslationCacheId(
              title,
              artist,
              targetLanguage,
            );
            await _cacheService.cacheTranslation(cacheId, transResult);
          }
          // Continue to next provider to collect more candidates; only yield
          // the first successful result for the actual display (auto-pick).
        } else if (cachedResult) {
          debugPrint(
            '[LyricsService.fetchTranslation]       ==> Found cached translation, breaking',
          );
          // Cached result: treat as first winner and stop the inner loop.
          break;
        }
      }
      if (transResult != null && transResult.translation) {
        // Yield the first result for display (first-wins for auto mode).
        if (firstYielded == null) {
          firstYielded = transResult;
          yield transResult;
        }
      } else if (transResult != null && transResult.source == 'SKIPPED') {
        debugPrint(
          '[LyricsService.fetchTranslation]       ==> Translation skipped by provider',
        );
        break;
      }
    }
  }
}
