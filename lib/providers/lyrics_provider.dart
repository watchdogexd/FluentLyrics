import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../models/setting.dart';
import '../models/lyric_provider_type.dart';
import '../constants/app_defaults.dart';
import '../services/media_service.dart';
import '../services/lyrics_service.dart';
import '../services/settings_service.dart';
import '../services/providers/lyrics_cache_service.dart';
import '../utils/lyric_aligner.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService mediaService = MediaService.create();
  final LyricsService _lyricsService = LyricsService();
  final SettingsService _settingsService = SettingsService();
  final LyricsCacheService _cacheService = LyricsCacheService();

  MediaMetadata? _currentMetadata;
  Timer? _permissionTimer;
  LyricsResult _lyricsResult = LyricsResult.empty();
  Duration _currentPosition = Duration.zero;

  // Settings
  Setting<int> _linesBefore = const Setting(
    current: AppDefaults.linesBefore,
    defaultValue: AppDefaults.linesBefore,
    changed: false,
  );
  Setting<int> _globalOffsetMs = const Setting(
    current: AppDefaults.globalOffsetMs,
    defaultValue: AppDefaults.globalOffsetMs,
    changed: false,
  );
  Setting<int> _scrollAutoResumeDelay = const Setting(
    current: AppDefaults.scrollAutoResumeDelay,
    defaultValue: AppDefaults.scrollAutoResumeDelay,
    changed: false,
  );
  Setting<bool> _blurEnabled = const Setting(
    current: AppDefaults.blurEnabled,
    defaultValue: AppDefaults.blurEnabled,
    changed: false,
  );
  Setting<bool> _richSyncEnabled = const Setting(
    current: AppDefaults.richSyncEnabled,
    defaultValue: AppDefaults.richSyncEnabled,
    changed: false,
  );
  Setting<List<LyricProviderType>> _trimMetadataProviders = const Setting(
    current: AppDefaults.trimMetadataProviders,
    defaultValue: AppDefaults.trimMetadataProviders,
    changed: false,
  );
  Setting<double> _fontSize = const Setting(
    current: AppDefaults.fontSize,
    defaultValue: AppDefaults.fontSize,
    changed: false,
  );
  Setting<double> _inactiveScale = const Setting(
    current: AppDefaults.inactiveScale,
    defaultValue: AppDefaults.inactiveScale,
    changed: false,
  );
  Setting<bool> _translationHighlightOnly = const Setting(
    current: AppDefaults.translationHighlightOnly,
    defaultValue: AppDefaults.translationHighlightOnly,
    changed: false,
  );

  // Translation Settings
  Setting<bool> _translationEnabled = const Setting(
    current: AppDefaults.translationEnabled,
    defaultValue: AppDefaults.translationEnabled,
    changed: false,
  );
  Setting<List<String>> _translationTargetLanguages = const Setting(
    current: AppDefaults.translationTargetLanguages,
    defaultValue: AppDefaults.translationTargetLanguages,
    changed: false,
  );
  Setting<List<String>> _translationIgnoredLanguages = const Setting(
    current: AppDefaults.translationIgnoredLanguages,
    defaultValue: AppDefaults.translationIgnoredLanguages,
    changed: false,
  );
  Setting<int> _translationBias = const Setting(
    current: AppDefaults.translationBias,
    defaultValue: AppDefaults.translationBias,
    changed: false,
  );
  Setting<String> _llmApiEndpoint = const Setting(
    current: AppDefaults.llmApiEndpoint,
    defaultValue: AppDefaults.llmApiEndpoint,
    changed: false,
  );
  Setting<String> _llmApiKey = const Setting(
    current: AppDefaults.llmApiKey,
    defaultValue: AppDefaults.llmApiKey,
    changed: false,
  );
  Setting<String> _llmModel = const Setting(
    current: AppDefaults.llmModel,
    defaultValue: AppDefaults.llmModel,
    changed: false,
  );
  Setting<bool> _keepScreenOn = const Setting(
    current: AppDefaults.keepScreenOn,
    defaultValue: AppDefaults.keepScreenOn,
    changed: false,
  );

  Duration _trackOffset = Duration.zero;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _androidPermissionGranted = !Platform.isAndroid;
  String _loadingStatus = '';

  MediaControlAbility _controlAbility = MediaControlAbility.none();
  DateTime? _playbackToggleLockedUntil;

  LyricsProvider() {
    _loadSettings();
    mediaService.addListener(_onMediaChanged);
    mediaService.startPolling();
    if (Platform.isAndroid) {
      _startPermissionPolling();
    }
  }

  void _startPermissionPolling() {
    _permissionTimer?.cancel();
    _permissionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkAndroidPermission();
    });
    checkAndroidPermission();
  }

  MediaMetadata? get currentMetadata => _currentMetadata;

  List<Lyric>? _cachedAlignedLyrics;
  LyricsResult? _lastLyricsResultForAlignment;
  bool? _lastRichSyncEnabledForAlignment;

  List<Lyric> _stripRichSync(List<Lyric> source) {
    return source.map((l) {
      if (l.inlineParts != null && l.inlineParts!.isNotEmpty) {
        return Lyric(
          startTime: l.startTime,
          endTime: l.endTime,
          text: l.text,
          inlineParts: null,
          translation: l.translation,
        );
      }
      return l;
    }).toList();
  }

  List<Lyric> get lyrics {
    final curRichSync = _richSyncEnabled.current;
    final baseLyrics =
        curRichSync ? _lyricsResult.lyrics : _stripRichSync(_lyricsResult.lyrics);

    if (_lyricsResult.subLyrics?.rawTranslation != null) {
      if (_cachedAlignedLyrics != null &&
          _lastLyricsResultForAlignment == _lyricsResult &&
          _lastRichSyncEnabledForAlignment == curRichSync) {
        return _cachedAlignedLyrics!;
      }
      _cachedAlignedLyrics = LyricAligner.align(
        originalLyrics: baseLyrics,
        rawTranslation: _lyricsResult.subLyrics!.rawTranslation!,
      );
      _lastLyricsResultForAlignment = _lyricsResult;
      _lastRichSyncEnabledForAlignment = curRichSync;
      return _cachedAlignedLyrics!;
    }

    return baseLyrics;
  }

  LyricsResult get lyricsResult {
    if (!_richSyncEnabled.current && _lyricsResult.isRichSync) {
      return _lyricsResult.copyWith(
        isRichSync: false,
        lyrics: lyrics, // Uses the getter above which strips inline parts
      );
    }
    return _lyricsResult;
  }

  Duration get currentPosition => _currentPosition;
  Duration get globalOffset => Duration(milliseconds: _globalOffsetMs.current);
  Duration get trackOffset => _trackOffset;
  int get currentIndex => _currentIndex;

  // Setting getters
  Setting<int> get linesBefore => _linesBefore;
  Setting<int> get scrollAutoResumeDelay => _scrollAutoResumeDelay;
  Setting<bool> get blurEnabled => _blurEnabled;
  Setting<bool> get richSyncEnabled => _richSyncEnabled;
  Setting<List<LyricProviderType>> get trimMetadataProviders =>
      _trimMetadataProviders;
  Setting<double> get fontSize => _fontSize;
  Setting<double> get inactiveScale => _inactiveScale;
  Setting<int> get globalOffsetSetting => _globalOffsetMs;

  Setting<bool> get translationEnabled => _translationEnabled;
  Setting<bool> get translationHighlightOnly => _translationHighlightOnly;
  Setting<List<String>> get translationTargetLanguages =>
      _translationTargetLanguages;
  Setting<List<String>> get translationIgnoredLanguages =>
      _translationIgnoredLanguages;
  Setting<int> get translationBias => _translationBias;
  Setting<String> get llmApiEndpoint => _llmApiEndpoint;
  Setting<String> get llmApiKey => _llmApiKey;
  Setting<String> get llmModel => _llmModel;
  Setting<bool> get keepScreenOn => _keepScreenOn;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get androidPermissionGranted => _androidPermissionGranted;
  String get loadingStatus => _loadingStatus;
  MediaControlAbility get controlAbility => _controlAbility;

  final Duration _interludeOffset = Duration(
    milliseconds: 500, // auto scroll takes 500ms
  );

  String? get currentCacheId {
    if (_currentMetadata == null) return null;
    return _cacheService.generateCacheId(
      _currentMetadata!.title,
      _currentMetadata!.artist,
      _currentMetadata!.album,
      _currentMetadata!.duration.inSeconds,
      isRichSync: _lyricsResult.isRichSync,
    );
  }

  bool get isInterlude {
    if (lyrics.isEmpty) return false;

    // Mid-song pause indicator (includes injected prelude)
    if (_currentIndex >= 0 && _currentIndex < lyrics.length) {
      if (lyrics[_currentIndex].text.trim().isEmpty) {
        return true;
      }
    }

    return false;
  }

  double get interludeProgress {
    if (!isInterlude || lyrics.isEmpty) return 0.0;
    final adjustedPosition = _currentPosition + globalOffset + _trackOffset;

    // Empty line progress (works for prelude too)
    if (_currentIndex >= 0 && _currentIndex < lyrics.length - 1) {
      final currentStartTime = lyrics[_currentIndex].startTime;
      final nextStartTime = lyrics[_currentIndex + 1].startTime;
      final duration =
          nextStartTime.inMilliseconds -
          currentStartTime.inMilliseconds -
          _interludeOffset.inMilliseconds;
      if (duration > 0) {
        return ((adjustedPosition.inMilliseconds -
                    currentStartTime.inMilliseconds) /
                duration)
            .clamp(0.0, 1.0);
      }
    }

    return 0.0;
  }

  Duration get interludeDuration {
    if (!isInterlude || lyrics.isEmpty) return Duration.zero;
    if (_currentIndex >= 0 && _currentIndex < lyrics.length - 1) {
      final currentStartTime = lyrics[_currentIndex].startTime;
      final nextStartTime = lyrics[_currentIndex + 1].startTime;
      return nextStartTime - currentStartTime - _interludeOffset;
    }
    return Duration.zero;
  }

  Future<void> _loadSettings() async {
    _linesBefore = await _settingsService.getLinesBefore();
    _globalOffsetMs = await _settingsService.getGlobalOffset();
    _scrollAutoResumeDelay = await _settingsService.getScrollAutoResumeDelay();
    _blurEnabled = await _settingsService.getBlurEnabled();
    _richSyncEnabled = await _settingsService.getRichSyncEnabled();
    _trimMetadataProviders = await _settingsService.getTrimMetadataProviders();
    _fontSize = await _settingsService.getFontSize();
    _inactiveScale = await _settingsService.getInactiveScale();

    _translationEnabled = await _settingsService.getTranslationEnabled();
    _translationHighlightOnly = await _settingsService
        .getTranslationHighlightOnly();
    _translationTargetLanguages = await _settingsService
        .getTranslationTargetLanguages();
    _translationIgnoredLanguages = await _settingsService
        .getTranslationIgnoredLanguages();
    _translationBias = await _settingsService.getTranslationBias();
    _llmApiEndpoint = await _settingsService.getLlmApiEndpoint();
    _llmApiKey = await _settingsService.getLlmApiKey();
    _llmModel = await _settingsService.getLlmModel();
    _keepScreenOn = await _settingsService.getKeepScreenOn();

    notifyListeners();
  }

  void setLinesBefore(int lines) {
    if (_linesBefore.current == lines) return;
    _linesBefore = Setting(
      current: lines,
      defaultValue: _linesBefore.defaultValue,
      changed: lines != _linesBefore.defaultValue,
    );
    _settingsService.setLinesBefore(lines);
    notifyListeners();
  }

  void setScrollAutoResumeDelay(int seconds) {
    if (_scrollAutoResumeDelay.current == seconds) return;
    _scrollAutoResumeDelay = Setting(
      current: seconds,
      defaultValue: _scrollAutoResumeDelay.defaultValue,
      changed: seconds != _scrollAutoResumeDelay.defaultValue,
    );
    _settingsService.setScrollAutoResumeDelay(seconds);
    notifyListeners();
  }

  void setBlurEnabled(bool enabled) {
    if (_blurEnabled.current == enabled) return;
    _blurEnabled = Setting(
      current: enabled,
      defaultValue: _blurEnabled.defaultValue,
      changed: enabled != _blurEnabled.defaultValue,
    );
    _settingsService.setBlurEnabled(enabled);
    notifyListeners();
  }

  void setRichSyncEnabled(bool enabled) {
    if (_richSyncEnabled.current == enabled) return;
    _richSyncEnabled = Setting(
      current: enabled,
      defaultValue: _richSyncEnabled.defaultValue,
      changed: enabled != _richSyncEnabled.defaultValue,
    );
    _settingsService.setRichSyncEnabled(enabled);
    notifyListeners();

    if (_currentMetadata != null) {
      _fetchLyrics(_currentMetadata!);
    }
  }

  void setTrimMetadataProviders(List<LyricProviderType> providers) {
    bool changed = !listEquals(providers, _trimMetadataProviders.defaultValue);
    _trimMetadataProviders = Setting(
      current: providers,
      defaultValue: _trimMetadataProviders.defaultValue,
      changed: changed,
    );
    _settingsService.setTrimMetadataProviders(providers);
    notifyListeners();
  }

  bool shouldTrimMetadata(LyricProviderType provider) {
    return _trimMetadataProviders.current.contains(provider);
  }

  void setFontSize(double size) {
    if (_fontSize.current == size) return;
    _fontSize = Setting(
      current: size,
      defaultValue: _fontSize.defaultValue,
      changed: size != _fontSize.defaultValue,
    );
    _settingsService.setFontSize(size);
    notifyListeners();
  }

  void setInactiveScale(double scale) {
    if (_inactiveScale.current == scale) return;
    _inactiveScale = Setting(
      current: scale,
      defaultValue: _inactiveScale.defaultValue,
      changed: scale != _inactiveScale.defaultValue,
    );
    _settingsService.setInactiveScale(scale);
    notifyListeners();
  }

  void setTranslationTargetLanguages(List<String> languages) {
    if (_translationTargetLanguages.current == languages) return;
    _translationTargetLanguages = Setting(
      current: languages,
      defaultValue: _translationTargetLanguages.defaultValue,
      changed: languages != _translationTargetLanguages.defaultValue,
    );
    _settingsService.setTranslationTargetLanguages(languages);
    notifyListeners();
  }

  void setTranslationIgnoredLanguages(List<String> languages) {
    // List comparison might need equality check logic if not handled by Setting
    // But listEquals is safer.
    if (listEquals(_translationIgnoredLanguages.current, languages)) return;
    _translationIgnoredLanguages = Setting(
      current: languages,
      defaultValue: _translationIgnoredLanguages.defaultValue,
      changed: !listEquals(
        languages,
        _translationIgnoredLanguages.defaultValue,
      ),
    );
    _settingsService.setTranslationIgnoredLanguages(languages);
    notifyListeners();
  }

  void setTranslationBias(int bias) {
    if (_translationBias.current == bias) return;
    _translationBias = Setting(
      current: bias,
      defaultValue: _translationBias.defaultValue,
      changed: bias != _translationBias.defaultValue,
    );
    _settingsService.setTranslationBias(bias);
    notifyListeners();
  }

  void setTranslationEnabled(bool enabled) {
    if (_translationEnabled.current == enabled) return;
    _translationEnabled = Setting(
      current: enabled,
      defaultValue: _translationEnabled.defaultValue,
      changed: enabled != _translationEnabled.defaultValue,
    );
    _settingsService.setTranslationEnabled(enabled);
    notifyListeners();
  }

  void setTranslationHighlightOnly(bool highlightOnly) {
    if (_translationHighlightOnly.current == highlightOnly) return;
    _translationHighlightOnly = Setting(
      current: highlightOnly,
      defaultValue: _translationHighlightOnly.defaultValue,
      changed: highlightOnly != _translationHighlightOnly.defaultValue,
    );
    _settingsService.setTranslationHighlightOnly(highlightOnly);
    notifyListeners();
  }

  void setLlmApiEndpoint(String endpoint) {
    if (_llmApiEndpoint.current == endpoint) return;
    _llmApiEndpoint = Setting(
      current: endpoint,
      defaultValue: _llmApiEndpoint.defaultValue,
      changed: endpoint != _llmApiEndpoint.defaultValue,
    );
    _settingsService.setLlmApiEndpoint(endpoint);
    notifyListeners();
  }

  void setLlmApiKey(String apiKey) {
    if (_llmApiKey.current == apiKey) return;
    _llmApiKey = Setting(
      current: apiKey,
      defaultValue: _llmApiKey.defaultValue,
      changed: apiKey != _llmApiKey.defaultValue,
    );
    _settingsService.setLlmApiKey(apiKey);
    notifyListeners();
  }

  void setLlmModel(String model) {
    if (_llmModel.current == model) return;
    _llmModel = Setting(
      current: model,
      defaultValue: _llmModel.defaultValue,
      changed: model != _llmModel.defaultValue,
    );
    _settingsService.setLlmModel(model);
    notifyListeners();
  }

  void setKeepScreenOn(bool enabled) {
    if (_keepScreenOn.current == enabled) return;
    _keepScreenOn = Setting(
      current: enabled,
      defaultValue: _keepScreenOn.defaultValue,
      changed: enabled != _keepScreenOn.defaultValue,
    );
    _settingsService.setKeepScreenOn(enabled);
    notifyListeners();
  }

  void setGlobalOffset(Duration offset) {
    final ms = offset.inMilliseconds;
    if (_globalOffsetMs.current == ms) return;
    _globalOffsetMs = Setting(
      current: ms,
      defaultValue: _globalOffsetMs.defaultValue,
      changed: ms != _globalOffsetMs.defaultValue,
    );
    _settingsService.setGlobalOffset(ms);
    _updateCurrentIndex();
    notifyListeners();
  }

  void setTrackOffset(Duration offset) {
    _trackOffset = offset;
    _updateCurrentIndex();
    notifyListeners();
  }

  void adjustTrackOffset(Duration delta) {
    _trackOffset += delta;
    _updateCurrentIndex();
    notifyListeners();
  }

  Future<void> playPause() async {
    // Optimistic toggle
    _isPlaying = !_isPlaying;
    _playbackToggleLockedUntil = DateTime.now().add(const Duration(seconds: 1));
    notifyListeners();

    try {
      await mediaService.controller.playPause();
    } catch (e) {
      // Revert on error
      _isPlaying = !_isPlaying;
      _playbackToggleLockedUntil = null;
      notifyListeners();
    }
  }

  Future<void> nextTrack() async {
    await mediaService.controller.nextTrack();
  }

  Future<void> previousTrack() async {
    await mediaService.controller.previousTrack();
  }

  Future<void> seek(Duration position) async {
    // Optimistic update
    _currentPosition = position;
    _updateCurrentIndex();
    notifyListeners();

    await mediaService.controller.seek(position);
  }

  void _onMediaChanged() {
    if (Platform.isAndroid) {
      checkAndroidPermission();
    }
    _syncWithMediaService();
  }

  Future<void> checkAndroidPermission() async {
    final service = mediaService;
    if (service is AndroidMediaService) {
      final granted = await service.checkPermission();
      if (_androidPermissionGranted != granted) {
        _androidPermissionGranted = granted;
        notifyListeners();
      }
    }
  }

  Future<void> clearCurrentTrackCache() async {
    if (_currentMetadata != null) {
      await _cacheService.clearTrackCache(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        _currentMetadata!.album,
        _currentMetadata!.duration.inSeconds,
      );
      if (_lyricsResult.subLyrics != null &&
          _lyricsResult.subLyrics!.language != null) {
        await _cacheService.clearTranslationCache(
          _cacheService.generateTranslationCacheId(
            _currentMetadata!.title,
            _currentMetadata!.artist,
            _lyricsResult.subLyrics!.language!,
          ),
        );
      }
      if (_currentMetadata != null) {
        // Force the fetching logic to re-search for artwork by resetting to 'fallback'.
        final systemMetadata = mediaService.metadata;
        if (systemMetadata?.artUrl == '' ||
            systemMetadata?.artUrl == 'fallback') {
          _currentMetadata = _currentMetadata!.copyWith(artUrl: 'fallback');
        }
        await _fetchLyrics(_currentMetadata!);
      }
    }
  }

  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
    if (_currentMetadata != null) {
      await _fetchLyrics(_currentMetadata!);
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  void _syncWithMediaService() {
    final metadata = mediaService.metadata;
    final isPlaying = mediaService.status.isPlaying;
    final position = mediaService.status.position;
    final controlAbility = mediaService.controlAbility;

    bool metadataChanged = false;

    MediaMetadata? processedMetadata = metadata;
    if (metadata != null &&
        metadata.artUrl == 'fallback' &&
        _currentMetadata != null &&
        _currentMetadata!.artUrl != 'fallback' &&
        _currentMetadata!.isSameTrack(metadata)) {
      processedMetadata = metadata.copyWith(artUrl: _currentMetadata!.artUrl);
    }

    final trackChanged = processedMetadata == null
        ? _currentMetadata != null
        : !processedMetadata.isSameTrack(_currentMetadata);
    final durationBecameValid =
        processedMetadata != null &&
        _currentMetadata != null &&
        _currentMetadata!.duration.inSeconds == 0 &&
        processedMetadata.duration.inSeconds > 0;

    if (trackChanged || durationBecameValid) {
      _currentMetadata = processedMetadata;
      metadataChanged = true;
      _trackOffset = Duration.zero;

      if (_currentMetadata != null) {
        if (_currentMetadata!.duration.inSeconds > 0) {
          _fetchLyrics(_currentMetadata!);
        } else {
          _isLoading = false;
          _lyricsResult = LyricsResult.empty();
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _lyricsResult = LyricsResult.empty();
        notifyListeners();
      }
    } else if (processedMetadata != _currentMetadata) {
      _currentMetadata = processedMetadata;
      metadataChanged = true;
    }

    bool capabilitiesChanged = _controlAbility != controlAbility;

    final now = DateTime.now();
    if (_playbackToggleLockedUntil == null ||
        now.isAfter(_playbackToggleLockedUntil!)) {
      _isPlaying = isPlaying;
      _playbackToggleLockedUntil = null;
    } else if (_isPlaying == isPlaying) {
      _playbackToggleLockedUntil = null;
    }

    _currentPosition = position;
    _controlAbility = controlAbility;
    _updateCurrentIndex();

    if (metadataChanged || isPlaying || capabilitiesChanged) {
      notifyListeners();
    }
  }

  void requestAndroidPermission() {
    final service = mediaService;
    if (service is AndroidMediaService) {
      service.openSettings();
    }
  }

  Future<void> _fetchLyrics(MediaMetadata metadata) async {
    _isLoading = true;
    _loadingStatus = 'Starting search...';
    _lyricsResult = LyricsResult.empty();
    notifyListeners();

    try {
      final stream = _lyricsService.fetchLyrics(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        onStatusUpdate: (status) {
          _loadingStatus = status;
          notifyListeners();
        },
        isCancelled: () => !metadata.isSameTrack(_currentMetadata),
        trimMetadataProviders: _trimMetadataProviders.current,
        richSyncEnabled: _richSyncEnabled.current,
        translationEnabled: _translationEnabled.current,
      );

      await for (var result in stream) {
        if (!metadata.isSameTrack(_currentMetadata)) return;

        result = result.trim();

        if (result.lyrics.isNotEmpty &&
            result.lyrics[0].startTime > const Duration(seconds: 3)) {
          final newLyrics = List<Lyric>.from(result.lyrics);
          newLyrics.insert(
            0,
            Lyric(
              text: '',
              startTime: Duration.zero,
              endTime: result.lyrics[0].startTime,
            ),
          );
          result = result.copyWith(lyrics: newLyrics);
        }

        _lyricsResult = result;
        if (result.lyrics.isNotEmpty || result.isPureMusic) {
          _isLoading = false;
        }

        if (_currentMetadata?.artUrl == 'fallback' &&
            result.artworkUrl != null) {
          _currentMetadata = _currentMetadata!.copyWith(
            artUrl: result.artworkUrl,
          );
        }

        _updateCurrentIndex();
        notifyListeners();
      }
    } catch (e) {
      if (!metadata.isSameTrack(_currentMetadata)) return;
      _loadingStatus = 'Error: $e';
    } finally {
      if (metadata.isSameTrack(_currentMetadata)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _updateCurrentIndex() {
    if (_lyricsResult.lyrics.isEmpty) {
      _currentIndex = -1;
      return;
    }

    final adjustedPosition = _currentPosition + globalOffset + _trackOffset;

    if (adjustedPosition < _lyricsResult.lyrics[0].startTime) {
      if (_currentIndex != -1) {
        _currentIndex = -1;
        notifyListeners();
      }
      return;
    }

    for (int i = 0; i < _lyricsResult.lyrics.length; i++) {
      if (adjustedPosition >= _lyricsResult.lyrics[i].startTime &&
          (i == _lyricsResult.lyrics.length - 1 ||
              adjustedPosition < _lyricsResult.lyrics[i + 1].startTime)) {
        if (_currentIndex != i) {
          _currentIndex = i;
          notifyListeners();
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    mediaService.removeListener(_onMediaChanged);
    mediaService.stopPolling();
    mediaService.dispose();
    super.dispose();
  }
}
