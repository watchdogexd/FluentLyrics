import '../models/lyric_provider_type.dart';

class LyricConfigurationHelper {
  const LyricConfigurationHelper._();

  static List<LyricProviderType> toggleTrimMetadataProvider(
    List<LyricProviderType> current,
    LyricProviderType providerType, {
    bool? select,
  }) {
    final updated = List<LyricProviderType>.from(current);
    final shouldSelect = select ?? !updated.contains(providerType);

    if (shouldSelect) {
      if (!updated.contains(providerType)) {
        updated.add(providerType);
      }
    } else {
      updated.remove(providerType);
    }

    return updated;
  }
}
