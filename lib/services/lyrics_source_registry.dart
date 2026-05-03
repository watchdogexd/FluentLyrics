import '../models/general_translation_request_data.dart';
import '../models/lyric_model.dart';
import '../models/lyric_provider_type.dart';
import 'providers/llm_translation_service.dart';
import 'providers/lrclib_service.dart';
import 'providers/lyrics_cache_service.dart';
import 'providers/musixmatch_service.dart';
import 'providers/netease_service.dart';
import 'providers/qqmusic_service.dart';

class LyricsFetchRequest {
  const LyricsFetchRequest({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.shouldTrimMetadata,
    required this.translationBias,
    this.onStatusUpdate,
    this.onArtworkUrl,
    this.onTranslation,
  });

  final String title;
  final List<String> artist;
  final String album;
  final int durationSeconds;
  final bool shouldTrimMetadata;
  final int translationBias;
  final Function(String)? onStatusUpdate;
  final Function(String)? onArtworkUrl;
  final Function(LyricsResult)? onTranslation;
}

class LyricsTranslationRequest {
  const LyricsTranslationRequest({
    required this.data,
    required this.targetLanguage,
    required this.translationBias,
  });

  final GeneralTranslationRequestData data;
  final String targetLanguage;
  final int translationBias;
}

abstract class LyricsSource {
  LyricProviderType get type;

  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request);

  bool checkTranslationSupport(String language) => false;

  Future<LyricsResult> fetchTranslation(
    LyricsTranslationRequest request,
  ) async {
    return LyricsResult.empty();
  }
}

class LyricsSourceRegistry {
  LyricsSourceRegistry({required Iterable<LyricsSource> sources})
    : _sources = {for (final source in sources) source.type: source};

  factory LyricsSourceRegistry.fromServices({
    required LrclibService lrclibService,
    required MusixmatchService musixmatchService,
    required NeteaseService neteaseService,
    required QQMusicService qqMusicService,
    required LlmTranslationService llmService,
    required LyricsCacheService cacheService,
  }) {
    return LyricsSourceRegistry(
      sources: [
        CacheLyricsSource(cacheService),
        LrclibLyricsSource(lrclibService),
        MusixmatchLyricsSource(musixmatchService),
        NeteaseLyricsSource(neteaseService),
        QQMusicLyricsSource(qqMusicService),
        LlmLyricsSource(llmService),
      ],
    );
  }

  final Map<LyricProviderType, LyricsSource> _sources;

  LyricsSource? sourceFor(LyricProviderType type) => _sources[type];
}

class CacheLyricsSource extends LyricsSource {
  CacheLyricsSource(this._service);

  final LyricsCacheService _service;

  @override
  LyricProviderType get type => LyricProviderType.cache;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      album: request.album,
      durationSeconds: request.durationSeconds,
    );
  }
}

class LrclibLyricsSource extends LyricsSource {
  LrclibLyricsSource(this._service);

  final LrclibService _service;

  @override
  LyricProviderType get type => LyricProviderType.lrclib;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      album: request.album,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
    );
  }
}

class MusixmatchLyricsSource extends LyricsSource {
  MusixmatchLyricsSource(this._service);

  final MusixmatchService _service;

  @override
  LyricProviderType get type => LyricProviderType.musixmatch;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
    );
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(request.data, request.targetLanguage);
  }
}

class NeteaseLyricsSource extends LyricsSource {
  NeteaseLyricsSource(this._service);

  final NeteaseService _service;

  @override
  LyricProviderType get type => LyricProviderType.netease;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      translationBias: request.translationBias,
      onTranslation: request.onTranslation,
    );
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(
      request.data,
      translationBias: request.translationBias,
    );
  }
}

class QQMusicLyricsSource extends LyricsSource {
  QQMusicLyricsSource(this._service);

  final QQMusicService _service;

  @override
  LyricProviderType get type => LyricProviderType.qqmusic;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      translationBias: request.translationBias,
      onTranslation: request.onTranslation,
    );
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(
      request.data,
      translationBias: request.translationBias,
    );
  }
}

class LlmLyricsSource extends LyricsSource {
  LlmLyricsSource(this._service);

  final LlmTranslationService _service;

  @override
  LyricProviderType get type => LyricProviderType.llm;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) async {
    return LyricsResult.empty();
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(request.data, request.targetLanguage);
  }
}
