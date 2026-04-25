import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/lyric_provider_type.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class LyricConfigurationSection extends StatelessWidget {
  final TextEditingController tokenController;
  final bool isFetchingToken;
  final VoidCallback onGetNewToken;
  final VoidCallback onTokenChanged;

  const LyricConfigurationSection({
    super.key,
    required this.tokenController,
    required this.isFetchingToken,
    required this.onGetNewToken,
    required this.onTokenChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: 'Lyric Configuration',
          description: 'Configure how lyrics are fetched and processed.',
          children: [
            SettingsToggleCard(
              title: 'Rich Sync',
              subtitle: 'Enable word-level synchronization.',
              value: provider.richSyncEnabled.current,
              onChanged: (value) => provider.setRichSyncEnabled(value),
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Global Lyrics Offset',
              subtitle:
                  'Set a default offset for all lyrics (e.g. if your device has audio latency).',
              value: (provider.globalOffset.inMilliseconds / 100).toDouble(),
              min: -50,
              max: 50,
              divisions: 100,
              label: (provider.globalOffset.inMilliseconds / 1000.0)
                  .toStringAsFixed(1),
              valueText:
                  '${(provider.globalOffset.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
              onChanged: (value) {
                provider.setGlobalOffset(
                  Duration(milliseconds: (value * 100).toInt()),
                );
              },
              onReset: provider.globalOffsetSetting.changed
                  ? () => provider.setGlobalOffset(Duration.zero)
                  : null,
              resetTooltip: 'Reset to 0s',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trim Metadata Lines',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attempt to remove staff/metadata lines from selected providers.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: LyricProviderType.values
                        .where((v) => v != LyricProviderType.cache)
                        .map((providerType) {
                          final isSelected = provider
                              .trimMetadataProviders
                              .current
                              .contains(providerType);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                final updated = List<LyricProviderType>.from(
                                  provider.trimMetadataProviders.current,
                                );
                                if (isSelected) {
                                  updated.remove(providerType);
                                } else {
                                  updated.add(providerType);
                                }
                                provider.setTrimMetadataProviders(updated);
                              },
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      final updated =
                                          List<LyricProviderType>.from(
                                            provider
                                                .trimMetadataProviders
                                                .current,
                                          );
                                      if (value == true) {
                                        updated.add(providerType);
                                      } else {
                                        updated.remove(providerType);
                                      }
                                      provider.setTrimMetadataProviders(
                                        updated,
                                      );
                                    },
                                    activeColor: Colors.blue,
                                    checkColor: Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    providerType.metadata['name'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Musixmatch Token',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Required for Musixmatch provider.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tokenController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your User Token',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => onTokenChanged(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isFetchingToken ? null : onGetNewToken,
                          icon: isFetchingToken
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Get New Token',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.orange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
