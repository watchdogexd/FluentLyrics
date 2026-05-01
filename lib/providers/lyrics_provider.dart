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
import '../utils/translation_helper.dart';
import '../utils/richify_helper.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService mediaService = MediaService.create();
  final LyricsService _lyricsService = LyricsService();
  final SettingsService _settingsService = SettingsService();
  final LyricsCacheService _cacheService = LyricsCacheService();

  MediaMetadata? _currentMetadata;
  Timer? _permissionTimer;
  LyricsResult _lyricsResult = LyricsResult.empty();
  LyricsResult? _translationResult;
  Duration _currentPosition = Duration.zero;
  final ValueNotifier<Duration> currentPositionNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<Duration> positionResyncNotifier = ValueNotifier(
    Duration.zero,
  );
  static const Duration _positionResyncThreshold = Duration(milliseconds: 400);

  // Settings
  Setting<bool> _cacheEnabled = const Setting(
    current: AppDefaults.cacheEnabled,
    defaultValue: AppDefaults.cacheEnabled,
    changed: false,
  );
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
  Setting<int> _translationAlignmentThreshold = const Setting(
    current: AppDefaults.translationAlignmentThreshold,
    defaultValue: AppDefaults.translationAlignmentThreshold,
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
  Setting<String> _llmReasoningEffort = const Setting(
    current: AppDefaults.llmReasoningEffort,
    defaultValue: AppDefaults.llmReasoningEffort,
    changed: false,
  );
  Setting<bool> _keepScreenOn = const Setting(
    current: AppDefaults.keepScreenOn,
    defaultValue: AppDefaults.keepScreenOn,
    changed: false,
  );
  Setting<bool> _backgroundMotionEnabled = const Setting(
    current: AppDefaults.backgroundMotionEnabled,
    defaultValue: AppDefaults.backgroundMotionEnabled,
    changed: false,
  );
  Setting<bool> _experimentalRichInlineFontSizeGlitching = const Setting(
    current: AppDefaults.experimentalRichInlineFontSizeGlitching,
    defaultValue: AppDefaults.experimentalRichInlineFontSizeGlitching,
    changed: false,
  );

  Duration _trackOffset = Duration.zero;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isFetching = false;
  bool _androidPermissionGranted = !Platform.isAndroid;
  String _loadingStatus = '';

  // Candidates
  List<LyricsResult> _candidates = [];
  bool _isPausedForCandidates = false;
  Completer<bool>? _candidatePauseCompleter;

  /// Set to true when the sheet is opened before the stream reaches the pause
  /// point, so the pause skips waiting and continues immediately.
  bool _candidateSheetOpenedEarly = false;

  // Translation candidates
  List<LyricsResult> _translationCandidates = [];
  int _translationRequestVersion = 0;

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
  LyricsResult? _lastTranslationResultForAlignment;
  bool? _lastRichSyncEnabledForAlignment;

  List<Lyric>? _cachedStrippedLyrics;
  LyricsResult? _lastLyricsResultForStripping;

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

    List<Lyric> baseLyrics;
    if (curRichSync) {
      baseLyrics = _lyricsResult.lyrics;
    } else {
      if (_cachedStrippedLyrics != null &&
          _lastLyricsResultForStripping == _lyricsResult) {
        baseLyrics = _cachedStrippedLyrics!;
      } else {
        baseLyrics = _stripRichSync(_lyricsResult.lyrics);
        _cachedStrippedLyrics = baseLyrics;
        _lastLyricsResultForStripping = _lyricsResult;
      }
    }

    if (_translationEnabled.current &&
        _translationResult?.rawTranslation != null) {
      if (_cachedAlignedLyrics != null &&
          _lastLyricsResultForAlignment == _lyricsResult &&
          _lastTranslationResultForAlignment == _translationResult &&
          _lastRichSyncEnabledForAlignment == curRichSync) {
        return _cachedAlignedLyrics!;
      }
      _cachedAlignedLyrics = TranslationHelper.align(
        originalLyrics: baseLyrics,
        rawTranslation: _translationResult!.rawTranslation!,
        similarityThreshold: _translationAlignmentThreshold.current,
      );
      _lastLyricsResultForAlignment = _lyricsResult;
      _lastTranslationResultForAlignment = _translationResult;
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

  LyricsResult? get translationResult =>
      _translationEnabled.current ? _translationResult : null;

  Duration get currentPosition => _currentPosition;
  Duration get globalOffset => Duration(milliseconds: _globalOffsetMs.current);
  Duration get trackOffset => _trackOffset;
  int get currentIndex => _currentIndex;

  // Setting getters
  Setting<bool> get cacheEnabled => _cacheEnabled;
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
  Setting<int> get translationAlignmentThreshold =>
      _translationAlignmentThreshold;
  Setting<String> get llmApiEndpoint => _llmApiEndpoint;
  Setting<String> get llmApiKey => _llmApiKey;
  Setting<String> get llmModel => _llmModel;
  Setting<String> get llmReasoningEffort => _llmReasoningEffort;
  Setting<bool> get keepScreenOn => _keepScreenOn;
  Setting<bool> get backgroundMotionEnabled => _backgroundMotionEnabled;
  Setting<bool> get experimentalRichInlineFontSizeGlitching =>
      _experimentalRichInlineFontSizeGlitching;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  bool get androidPermissionGranted => _androidPermissionGranted;
  String get loadingStatus => _loadingStatus;
  MediaControlAbility get controlAbility => _controlAbility;
  final ValueNotifier<List<String>> artworkUrlsNotifier = ValueNotifier([]);

  // Candidates getters
  List<LyricsResult> get candidates => _candidates;
  bool get isPausedForCandidates => _isPausedForCandidates;
  List<LyricsResult> get translationCandidates => _translationCandidates;

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
    return interludeProgressForPosition(_currentPosition);
  }

  void _clearTranslationState({bool clearCandidates = true}) {
    _translationResult = null;
    _cachedAlignedLyrics = null;
    _lastTranslationResultForAlignment = null;
    _lastRichSyncEnabledForAlignment = null;
    if (clearCandidates) {
      _translationCandidates = [];
    }
  }

  void _invalidateTranslationRequests({bool clearCandidates = true}) {
    _translationRequestVersion++;
    _clearTranslationState(clearCandidates: clearCandidates);
  }

  int _beginTranslationRequest() {
    _translationRequestVersion++;
    return _translationRequestVersion;
  }

  bool _canAcceptTranslationResult(MediaMetadata metadata, int requestVersion) {
    return _translationEnabled.current &&
        requestVersion == _translationRequestVersion &&
        metadata.isSameTrack(_currentMetadata);
  }

  double interludeProgressForPosition(Duration position) {
    if (!isInterlude || lyrics.isEmpty) return 0.0;
    final adjustedPosition = position + globalOffset + _trackOffset;

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

  bool _setLoadingStatus(String status) {
    if (_loadingStatus == status) return false;
    _loadingStatus = status;
    return true;
  }

  bool _setFetchingState(bool isFetching) {
    if (_isFetching == isFetching) return false;
    _isFetching = isFetching;
    return true;
  }

  bool _setLoadingState(bool isLoading) {
    if (_isLoading == isLoading) return false;
    _isLoading = isLoading;
    return true;
  }

  Future<void> _loadSettings() async {
    _cacheEnabled = await _settingsService.getCacheEnabled();
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
    _translationAlignmentThreshold = await _settingsService
        .getTranslationAlignmentThreshold();
    _llmApiEndpoint = await _settingsService.getLlmApiEndpoint();
    _llmApiKey = await _settingsService.getLlmApiKey();
    _llmModel = await _settingsService.getLlmModel();
    _llmReasoningEffort = await _settingsService.getLlmReasoningEffort();
    _keepScreenOn = await _settingsService.getKeepScreenOn();
    _backgroundMotionEnabled = await _settingsService
        .getBackgroundMotionEnabled();
    _experimentalRichInlineFontSizeGlitching = await _settingsService
        .getExperimentalRichInlineFontSizeGlitching();

    notifyListeners();
  }

  void setCacheEnabled(bool enabled) {
    if (_cacheEnabled.current == enabled) return;
    _cacheEnabled = Setting(
      current: enabled,
      defaultValue: _cacheEnabled.defaultValue,
      changed: enabled != _cacheEnabled.defaultValue,
    );
    _settingsService.setCacheEnabled(enabled);
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

  void setTranslationAlignmentThreshold(int threshold) {
    if (_translationAlignmentThreshold.current == threshold) return;
    _translationAlignmentThreshold = Setting(
      current: threshold,
      defaultValue: _translationAlignmentThreshold.defaultValue,
      changed: threshold != _translationAlignmentThreshold.defaultValue,
    );
    _settingsService.setTranslationAlignmentThreshold(threshold);

    // Changing the threshold requires realigning lyrics
    _lastTranslationResultForAlignment = null;
    notifyListeners();
  }

  void setTranslationEnabled(bool enabled) {
    if (_translationEnabled.current == enabled) return;
    final wasEnabled = _translationEnabled.current;
    _translationEnabled = Setting(
      current: enabled,
      defaultValue: _translationEnabled.defaultValue,
      changed: enabled != _translationEnabled.defaultValue,
    );
    _settingsService.setTranslationEnabled(enabled);
    if (!enabled) {
      _invalidateTranslationRequests();
      notifyListeners();
      return;
    }
    notifyListeners();

    if (!wasEnabled &&
        _currentMetadata != null &&
        _lyricsResult.lyrics.isNotEmpty &&
        _translationResult == null) {
      unawaited(_fetchTranslationsForCurrentTrack(_currentMetadata!));
    }
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

  void setLlmReasoningEffort(String effort) {
    if (_llmReasoningEffort.current == effort) return;
    _llmReasoningEffort = Setting(
      current: effort,
      defaultValue: _llmReasoningEffort.defaultValue,
      changed: effort != _llmReasoningEffort.defaultValue,
    );
    _settingsService.setLlmReasoningEffort(effort);
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

  void setBackgroundMotionEnabled(bool enabled) {
    if (_backgroundMotionEnabled.current == enabled) return;
    _backgroundMotionEnabled = Setting(
      current: enabled,
      defaultValue: _backgroundMotionEnabled.defaultValue,
      changed: enabled != _backgroundMotionEnabled.defaultValue,
    );
    _settingsService.setBackgroundMotionEnabled(enabled);
    notifyListeners();
  }

  void setExperimentalRichInlineFontSizeGlitching(bool enabled) {
    if (_experimentalRichInlineFontSizeGlitching.current == enabled) return;
    _experimentalRichInlineFontSizeGlitching = Setting(
      current: enabled,
      defaultValue: _experimentalRichInlineFontSizeGlitching.defaultValue,
      changed: enabled != _experimentalRichInlineFontSizeGlitching.defaultValue,
    );
    _settingsService.setExperimentalRichInlineFontSizeGlitching(enabled);
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
    _setCurrentPosition(position, forceResync: true);
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
      if (_translationResult != null && _translationResult!.language != null) {
        await _cacheService.clearTranslationCache(
          _cacheService.generateTranslationCacheId(
            _currentMetadata!.title,
            _currentMetadata!.artist,
            _translationResult!.language!,
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

      // Cancel any pending candidate pause for the old track.
      _candidatePauseCompleter?.complete(false);
      _candidatePauseCompleter = null;
      _isPausedForCandidates = false;
      _candidateSheetOpenedEarly = false;
      _candidates = [];
      _invalidateTranslationRequests();

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

    final playbackChanged = _isPlaying != isPlaying;
    final capabilitiesChanged = _controlAbility != controlAbility;

    final now = DateTime.now();
    if (_playbackToggleLockedUntil == null ||
        now.isAfter(_playbackToggleLockedUntil!)) {
      _isPlaying = isPlaying;
      _playbackToggleLockedUntil = null;
    } else if (_isPlaying == isPlaying) {
      _playbackToggleLockedUntil = null;
    }

    _setCurrentPosition(position);
    _controlAbility = controlAbility;
    final indexChanged = _updateCurrentIndex();

    if (metadataChanged ||
        playbackChanged ||
        capabilitiesChanged ||
        indexChanged) {
      notifyListeners();
    }
  }

  void requestAndroidPermission() {
    final service = mediaService;
    if (service is AndroidMediaService) {
      service.openSettings();
    }
  }

  Future<void> _fetchTranslationsForCurrentTrack(
    MediaMetadata metadata, {
    bool showLoadingState = false,
    bool clearCachedTranslations = false,
  }) async {
    if (!_translationEnabled.current || _lyricsResult.lyrics.isEmpty) return;

    if (clearCachedTranslations) {
      for (final lang in _translationTargetLanguages.current) {
        await _cacheService.clearTranslationCache(
          _cacheService.generateTranslationCacheId(
            metadata.title,
            metadata.artist,
            lang,
          ),
        );
      }
    }

    final requestVersion = _beginTranslationRequest();
    _clearTranslationState();

    var shouldNotify = false;
    if (showLoadingState) {
      shouldNotify =
          _setFetchingState(true) ||
          _setLoadingStatus('Refreshing translations...') ||
          shouldNotify;
    }
    if (shouldNotify) {
      notifyListeners();
    }

    try {
      final transStream = _lyricsService.fetchTranslation(
        bestResult: _lyricsResult,
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        isCancelled: () =>
            !_canAcceptTranslationResult(metadata, requestVersion),
        onTranslationCandidate: (trans) {
          if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
          final isDuplicate = _translationCandidates.any(
            (c) =>
                c.translationProvider == trans.translationProvider &&
                c.language == trans.language,
          );
          if (!isDuplicate) {
            _translationCandidates = List.unmodifiable([
              ..._translationCandidates,
              trans,
            ]);
            notifyListeners();
          }
        },
      );

      await for (var transResult in transStream) {
        if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
        _translationResult = transResult;
        _cachedAlignedLyrics = null;
        _updateCurrentIndex();
        notifyListeners();
      }
    } catch (e) {
      if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
      if (_setLoadingStatus('Error: $e')) {
        notifyListeners();
      }
    } finally {
      if (showLoadingState &&
          metadata.isSameTrack(_currentMetadata) &&
          (requestVersion == _translationRequestVersion ||
              !_translationEnabled.current)) {
        if (_setFetchingState(false)) {
          notifyListeners();
        }
      }
    }
  }

  Future<void> _fetchLyrics(
    MediaMetadata metadata, {
    bool skipFetchTranslations = false,
  }) async {
    _isFetching = true;
    _isLoading = true;
    _loadingStatus = 'Starting search...';
    _lyricsResult = LyricsResult.empty();
    _invalidateTranslationRequests();
    _candidates = [];
    _isPausedForCandidates = false;
    _candidateSheetOpenedEarly = false;
    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    artworkUrlsNotifier.value = [];
    notifyListeners();

    try {
      final stream = _lyricsService.fetchLyrics(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        onStatusUpdate: (status) {
          if (_setLoadingStatus(status)) {
            notifyListeners();
          }
        },
        onFetchStatusUpdate: (status) {
          if (_setFetchingState(status)) {
            notifyListeners();
          }
        },
        isCancelled: () => !metadata.isSameTrack(_currentMetadata),
        trimMetadataProviders: _trimMetadataProviders.current,
        richSyncEnabled: _richSyncEnabled.current,
        onTranslation: (trans) {
          if (!metadata.isSameTrack(_currentMetadata) ||
              !_translationEnabled.current ||
              trans.rawTranslation!.isEmpty ||
              trans.language == null) {
            return;
          }

          String lowercaseTransLang = trans.language!.toLowerCase();
          bool match = false;
          for (var target in _translationTargetLanguages.current) {
            if (target.toLowerCase() == lowercaseTransLang) {
              match = true;
              break;
            }
          }
          if (!match) return;

          // save to translation candidates
          final isDuplicate = _translationCandidates.any(
            (c) =>
                c.translationProvider == trans.translationProvider &&
                c.language == trans.language,
          );
          if (!isDuplicate) {
            _translationCandidates = List.unmodifiable([
              ..._translationCandidates,
              trans,
            ]);
          }

          if (_translationResult == null) {
            _translationResult = trans;
            notifyListeners();
            if (_cacheEnabled.current &&
                (trans.translation || trans.source == 'SKIPPED')) {
              final cacheId = _cacheService.generateTranslationCacheId(
                metadata.title,
                metadata.artist,
                trans.language!,
              );
              _cacheService.cacheTranslation(cacheId, trans).then((_) {
                debugPrint(
                  'Cached translation from ${trans.source} for ${metadata.title} - ${metadata.artist.join(', ')}',
                );
              });
            }
          }
        },
        onCandidate: (candidate) {
          if (!metadata.isSameTrack(_currentMetadata)) return;
          // Avoid duplicates: same source + sync type.
          final isDuplicate = _candidates.any(
            (c) =>
                c.source == candidate.source &&
                c.isSynced == candidate.isSynced &&
                c.isRichSync == candidate.isRichSync,
          );
          if (!isDuplicate) {
            _candidates = List.unmodifiable([..._candidates, candidate]);
            notifyListeners();
          }
        },
        onPauseForCandidates: () async {
          if (!metadata.isSameTrack(_currentMetadata)) return false;
          // If the sheet was opened before we reached this point, skip waiting.
          if (_candidateSheetOpenedEarly) {
            _candidateSheetOpenedEarly = false;
            return true;
          }
          _candidatePauseCompleter = Completer<bool>();
          _isPausedForCandidates = true;
          notifyListeners();
          return _candidatePauseCompleter!.future;
        },
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
        if (result.artworkUrls != null && result.artworkUrls!.isNotEmpty) {
          final newUrls = result.artworkUrls!
              .where((url) => !artworkUrlsNotifier.value.contains(url))
              .toList();
          if (newUrls.isNotEmpty) {
            artworkUrlsNotifier.value = List.from(artworkUrlsNotifier.value)
              ..addAll(newUrls);
          }
        }

        if (result.lyrics.isNotEmpty || result.isPureMusic) {
          _setLoadingState(false);
        }

        _updateCurrentIndex();
        notifyListeners();
      }

      if (!metadata.isSameTrack(_currentMetadata)) return;

      if (_translationEnabled.current &&
          !skipFetchTranslations &&
          _lyricsResult.lyrics.isNotEmpty &&
          _translationResult == null) {
        await _fetchTranslationsForCurrentTrack(metadata);
      }
    } catch (e) {
      if (!metadata.isSameTrack(_currentMetadata)) return;
      _setLoadingStatus('Error: $e');
    } finally {
      if (metadata.isSameTrack(_currentMetadata)) {
        _isPausedForCandidates = false;
        _candidatePauseCompleter?.complete(false);
        _candidatePauseCompleter = null;
        _setLoadingState(false);
        notifyListeners();
      }
    }
  }

  /// Called when the user opens the candidates sheet.
  /// If the stream is already paused, completes the Completer to resume.
  /// If the stream hasn't reached the pause point yet, sets a flag so it
  /// skips the wait when it eventually does.
  void resumeCandidateFetch() {
    if (_isPausedForCandidates && _candidatePauseCompleter != null) {
      // Already paused — wake it up.
      _isPausedForCandidates = false;
      _candidatePauseCompleter!.complete(true);
      _candidatePauseCompleter = null;
      notifyListeners();
    } else if (!_isPausedForCandidates && _candidatePauseCompleter == null) {
      // Sheet opened before the stream reached the pause point.
      _candidateSheetOpenedEarly = true;
    }
  }

  /// Replaces the current lyrics display with [candidate] and persists it to
  /// the Isar cache so subsequent loads use this selection.
  Future<void> selectCandidate(LyricsResult candidate) async {
    if (_currentMetadata == null) return;

    // Cancel any ongoing candidate fetch for this track.
    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    _isPausedForCandidates = false;

    // Trim and prepend silence if needed (mirrors _fetchLyrics behaviour).
    LyricsResult result = candidate.trim();
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
    _updateCurrentIndex();
    notifyListeners();

    if (_cacheEnabled.current) {
      await _cacheService.cacheLyrics(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        _currentMetadata!.album,
        _currentMetadata!.duration.inSeconds,
        candidate, // store the raw (un-trimmed) result so re-loads are consistent
      );
      debugPrint(
        '[LyricsProvider] Candidate from ${candidate.source} saved to cache.',
      );
    }
  }

  /// Merges word-level timing from [richSource] into [syncedTarget], producing
  /// a new rich-synced result that is applied and cached immediately.
  Future<void> richifyCandidate({
    required LyricsResult syncedTarget,
    required LyricsResult richSource,
  }) async {
    if (_currentMetadata == null) return;

    final richified = RichifyHelper.apply(
      syncedTarget: syncedTarget,
      richSource: richSource,
    );

    // Add to the candidate list so it shows up (and is marked active) in the
    // sheet after the user returns to it.
    _candidates = List.unmodifiable([..._candidates, richified]);

    // Reuse selectCandidate so trimming + silence prepending is consistent.
    await selectCandidate(richified);
  }

  /// Replaces the current translation with [candidate] and persists it to the
  /// Isar cache so subsequent loads use this selection.
  Future<void> selectTranslationCandidate(LyricsResult candidate) async {
    if (_currentMetadata == null) return;
    _translationResult = candidate;
    _cachedAlignedLyrics = null; // Invalidate alignment cache.
    _updateCurrentIndex();
    notifyListeners();

    if (_cacheEnabled.current && candidate.language != null) {
      final targetLanguage = candidate.language!;
      final cacheId = _cacheService.generateTranslationCacheId(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        targetLanguage,
      );
      await _cacheService.cacheTranslation(cacheId, candidate);
      debugPrint(
        '[LyricsProvider] Translation candidate from ${candidate.translationProvider} saved to cache.',
      );
    }
  }

  /// Manually re-fires the lyrics fetch logic without resetting the album art.
  Future<void> refetchLyrics() async {
    final metadata = _currentMetadata;
    if (metadata != null) {
      await _cacheService.clearTrackCache(
        metadata.title,
        metadata.artist,
        metadata.album,
        metadata.duration.inSeconds,
      );
      await _fetchLyrics(metadata);
    }
  }

  /// Manually re-fires the translation fetch logic to refresh translations.
  Future<void> refetchTranslations() async {
    final metadata = _currentMetadata;
    if (metadata == null) return;
    if (!_translationEnabled.current) return;
    if (_lyricsResult.lyrics.isEmpty) return;
    await _fetchTranslationsForCurrentTrack(
      metadata,
      showLoadingState: true,
      clearCachedTranslations: true,
    );
  }

  bool _updateCurrentIndex() {
    final previousIndex = _currentIndex;
    if (_lyricsResult.lyrics.isEmpty) {
      _currentIndex = -1;
      return previousIndex != _currentIndex;
    }

    final adjustedPosition = _currentPosition + globalOffset + _trackOffset;

    if (adjustedPosition < _lyricsResult.lyrics[0].startTime) {
      _currentIndex = -1;
      return previousIndex != _currentIndex;
    }

    int low = 0;
    int high = _lyricsResult.lyrics.length - 1;
    int matchedIndex = -1;

    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      if (_lyricsResult.lyrics[mid].startTime <= adjustedPosition) {
        matchedIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    _currentIndex = matchedIndex;
    final indexChanged = previousIndex != _currentIndex;
    if (indexChanged) {
      positionResyncNotifier.value = _currentPosition;
    }
    return indexChanged;
  }

  void _setCurrentPosition(Duration position, {bool forceResync = false}) {
    if (_currentPosition == position) return;
    final previousPosition = _currentPosition;
    _currentPosition = position;
    currentPositionNotifier.value = position;

    final delta = position - previousPosition;
    if (forceResync ||
        delta < Duration.zero ||
        delta > _positionResyncThreshold) {
      positionResyncNotifier.value = position;
    }
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    mediaService.removeListener(_onMediaChanged);
    mediaService.stopPolling();
    mediaService.dispose();
    currentPositionNotifier.dispose();
    positionResyncNotifier.dispose();
    artworkUrlsNotifier.dispose();
    super.dispose();
  }
}
