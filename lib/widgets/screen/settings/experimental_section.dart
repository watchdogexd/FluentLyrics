import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_toggle_card.dart';

class ExperimentalSection extends StatelessWidget {
  const ExperimentalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: 'Experimental',
          description: 'Try out new features. Some may be unstable.',
          children: [
            SettingsToggleCard(
              title: 'Rich Parts Fonts Size Glitching Fix',
              subtitle:
                  'Enable the font size adjustment (divide by 0.9) for rich inline lyrics. This fixes alignment issues with certain fonts, or on some devices.',
              value: provider.experimentalRichInlineFontSizeGlitching.current,
              onChanged: (value) =>
                  provider.setExperimentalRichInlineFontSizeGlitching(value),
            ),
          ],
        );
      },
    );
  }
}
