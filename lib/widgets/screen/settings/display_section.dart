import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class DisplaySection extends StatelessWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: 'Display Configuration',
          description: 'Adjust how lyrics are displayed.',
          children: [
            SettingsSliderCard(
              title: 'Font Size',
              subtitle: 'Size of the lyric text in pixels.',
              value: provider.fontSize.current,
              min: 12,
              max: 64,
              divisions: 52,
              label: provider.fontSize.current.toInt().toString(),
              valueText: '${provider.fontSize.current.toInt()}',
              onChanged: (value) => provider.setFontSize(value),
              onReset:
                  provider.fontSize.changed
                      ? () =>
                          provider.setFontSize(provider.fontSize.defaultValue)
                      : null,
              resetTooltip: 'Reset to 36px',
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Inactive Line Scale',
              subtitle: 'Scale factor for non-highlighted lines.',
              value: provider.inactiveScale.current,
              min: 0.5,
              max: 1.0,
              divisions: 50,
              label: '${(provider.inactiveScale.current * 100).toInt()}%',
              valueText: '${(provider.inactiveScale.current * 100).toInt()}%',
              onChanged: (value) => provider.setInactiveScale(value),
              onReset:
                  provider.inactiveScale.changed
                      ? () => provider.setInactiveScale(
                        provider.inactiveScale.defaultValue,
                      )
                      : null,
              resetTooltip: 'Reset to 85%',
            ),
            const SizedBox(height: 24),
            SettingsToggleCard(
              title: 'Blur Effect',
              subtitle: 'Blur non-active lyric lines for focus.',
              value: provider.blurEnabled.current,
              onChanged: (value) => provider.setBlurEnabled(value),
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Lines Before Active',
              subtitle:
                  'Number of preceding lines to show when auto-scrolling.',
              value: provider.linesBefore.current.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: provider.linesBefore.current.toString(),
              valueText: '${provider.linesBefore.current}',
              onChanged: (value) => provider.setLinesBefore(value.toInt()),
              onReset:
                  provider.linesBefore.changed
                      ? () => provider.setLinesBefore(
                        provider.linesBefore.defaultValue,
                      )
                      : null,
              resetTooltip: 'Reset to 2',
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Auto-Resume Delay',
              subtitle:
                  'Time to wait before auto-scrolling resumes after you manual scroll.',
              value: provider.scrollAutoResumeDelay.current.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: '${provider.scrollAutoResumeDelay.current}s',
              valueText: '${provider.scrollAutoResumeDelay.current}s',
              onChanged: (value) =>
                  provider.setScrollAutoResumeDelay(value.toInt()),
              onReset:
                  provider.scrollAutoResumeDelay.changed
                      ? () => provider.setScrollAutoResumeDelay(
                        provider.scrollAutoResumeDelay.defaultValue,
                      )
                      : null,
              resetTooltip: 'Reset to 5s',
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 24),
              SettingsToggleCard(
                title: 'Keep Screen On',
                subtitle:
                    'Prevent device from sleeping while lyrics screen is active.',
                value: provider.keepScreenOn.current,
                onChanged: (value) => provider.setKeepScreenOn(value),
              ),
            ],
          ],
        );
      },
    );
  }
}
