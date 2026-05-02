import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/utils/lyric_configuration_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggleTrimMetadataProvider adds provider when absent', () {
    final updated = LyricConfigurationHelper.toggleTrimMetadataProvider(
      [LyricProviderType.lrclib],
      LyricProviderType.netease,
    );

    expect(updated, [LyricProviderType.lrclib, LyricProviderType.netease]);
  });

  test('toggleTrimMetadataProvider removes provider when present', () {
    final updated = LyricConfigurationHelper.toggleTrimMetadataProvider(
      [LyricProviderType.lrclib, LyricProviderType.netease],
      LyricProviderType.netease,
    );

    expect(updated, [LyricProviderType.lrclib]);
  });

  test('toggleTrimMetadataProvider respects explicit select argument', () {
    final selected = LyricConfigurationHelper.toggleTrimMetadataProvider(
      [LyricProviderType.lrclib],
      LyricProviderType.netease,
      select: true,
    );
    final deselected = LyricConfigurationHelper.toggleTrimMetadataProvider(
      [LyricProviderType.lrclib, LyricProviderType.netease],
      LyricProviderType.netease,
      select: false,
    );

    expect(selected, [LyricProviderType.lrclib, LyricProviderType.netease]);
    expect(deselected, [LyricProviderType.lrclib]);
  });
}
