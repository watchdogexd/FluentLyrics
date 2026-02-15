import '../models/lyric_provider_type.dart';

class AppDefaults {
  static const int linesBefore = 1;
  static const int globalOffsetMs = 0;
  static const int scrollAutoResumeDelay = 5;
  static const bool blurEnabled = true;
  static const bool richSyncEnabled = true;
  static const List<LyricProviderType> trimMetadataProviders = [
    LyricProviderType.netease,
    LyricProviderType.qqmusic,
  ];
  static const double fontSize = 36.0;
  static const double inactiveScale = 0.85;
  static const List<LyricProviderType> providerPriority = [
    LyricProviderType.musixmatch,
    LyricProviderType.netease,
    LyricProviderType.qqmusic,
    LyricProviderType.lrclib,
  ];
  static const int enabledProviderCount = 3;
  static const bool cacheEnabled = true;
  static const bool translationEnabled = false;
  static const List<String> translationTargetLanguages = ['zht', 'zh_CN'];
  static const bool translationHighlightOnly = true;
  static const List<String> translationIgnoredLanguages = [];
  static const int translationBias = 50;
  static const String? musixmatchToken = null;
  static const String llmApiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String llmApiKey = '';
  static const String llmModel = 'openai/gpt-oss-120b';
}
