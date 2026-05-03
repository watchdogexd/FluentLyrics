part of '../media_service.dart';

class MacOSMediaService extends MediaService implements MediaController {
  static const MethodChannel _channel = MethodChannel(
    'cc.koto.fluent_lyrics/media',
  );
  static const Duration _activePollInterval = Duration(milliseconds: 250);
  static const Duration _idlePollInterval = Duration(seconds: 1);
  static const Duration _disconnectedPollInterval = Duration(seconds: 2);

  Timer? _pollTimer;
  MediaMetadata? _metadata;
  MediaPlaybackStatus _status = MediaPlaybackStatus.empty();
  MediaControlAbility _controlAbility = MediaControlAbility.none();
  bool _isUpdating = false;
  bool _isPolling = false;
  int _pollSession = 0;
  int _emptyResultCount = 0;

  @override
  MediaMetadata? get metadata => _metadata;
  @override
  MediaPlaybackStatus get status => _status;
  @override
  MediaControlAbility get controlAbility => _controlAbility;
  @override
  MediaController get controller => this;

  @override
  void startPolling() {
    _pollSession++;
    _isPolling = true;
    _scheduleNextPoll(Duration.zero, _pollSession);
  }

  @override
  void stopPolling() {
    _pollSession++;
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _scheduleNextPoll(Duration delay, int session) {
    if (!_isPolling || session != _pollSession) return;
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, () => _updateState(session));
  }

  Duration _nextPollDelay({
    required bool hasMetadata,
    required bool isPlaying,
  }) {
    if (!hasMetadata) return _disconnectedPollInterval;
    return isPlaying ? _activePollInterval : _idlePollInterval;
  }

  Future<void> _updateState(int session) async {
    if (session != _pollSession) {
      return;
    }
    if (_isUpdating) {
      return;
    }
    _isUpdating = true;
    var nextPollDelay = _nextPollDelay(
      hasMetadata: _metadata != null,
      isPlaying: _status.isPlaying,
    );
    try {
      final Map? result = await _channel.invokeMethod('getStatus');
      if (result == null) {
        _emptyResultCount++;
        nextPollDelay = _disconnectedPollInterval;
        if (_emptyResultCount >= 4 &&
            (_metadata != null || _status != MediaPlaybackStatus.empty())) {
          _metadata = null;
          _status = MediaPlaybackStatus.empty();
          _controlAbility = MediaControlAbility.none();
          notifyListeners();
        }
        return;
      }
      _emptyResultCount = 0;

      final metadataMap = result['metadata'] as Map?;
      MediaMetadata? newMetadata;
      if (metadataMap != null) {
        final rawArtist = metadataMap['artist'];
        List<String> artist = ['Unknown Artist'];
        if (rawArtist is String && rawArtist.isNotEmpty) {
          artist = [rawArtist];
        } else if (rawArtist is List) {
          artist = rawArtist.map((e) => e.toString()).toList();
        }

        final rawDuration = metadataMap['duration'];
        final durationMs = rawDuration is num ? rawDuration.toInt() : 0;

        newMetadata = MediaMetadata(
          title: metadataMap['title'] ?? 'Unknown Title',
          artist: artist,
          album: metadataMap['album'] ?? 'Unknown Album',
          duration: Duration(milliseconds: durationMs),
          artUrl:
              (metadataMap['artUrl'] == null ||
                  (metadataMap['artUrl'] as String).isEmpty)
              ? 'fallback'
              : metadataMap['artUrl'],
        );
      }

      final abilityMap = result['controlAbility'] as Map?;
      final rawPosition = result['position'];
      final positionMs = rawPosition is num ? rawPosition.toInt() : 0;
      final newStatus = MediaPlaybackStatus(
        isPlaying: result['isPlaying'] ?? false,
        position: Duration(milliseconds: positionMs),
      );
      nextPollDelay = _nextPollDelay(
        hasMetadata: newMetadata != null,
        isPlaying: newStatus.isPlaying,
      );
      final newAbility = abilityMap != null
          ? MediaControlAbility(
              canPlayPause: abilityMap['canPlayPause'] ?? false,
              canGoNext: abilityMap['canGoNext'] ?? false,
              canGoPrevious: abilityMap['canGoPrevious'] ?? false,
              canSeek: abilityMap['canSeek'] ?? false,
            )
          : MediaControlAbility.none();

      if (_metadata != newMetadata ||
          _status != newStatus ||
          _controlAbility != newAbility) {
        _metadata = newMetadata;
        _status = newStatus;
        _controlAbility = newAbility;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.debug('Failed to get macOS media info: $e');
    } finally {
      _isUpdating = false;
      _scheduleNextPoll(nextPollDelay, session);
    }
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  @override
  Future<void> playPause() async {
    await _channel.invokeMethod('playPause');
  }

  @override
  Future<void> nextTrack() async {
    await _channel.invokeMethod('nextTrack');
  }

  @override
  Future<void> previousTrack() async {
    await _channel.invokeMethod('previousTrack');
  }

  @override
  Future<void> seek(Duration position) async {
    await _channel.invokeMethod('seek', {'position': position.inMilliseconds});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
