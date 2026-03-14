import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class TranslationSection extends StatelessWidget {
  const TranslationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: 'Translation Configuration',
          description: 'Configure translation settings.',
          children: [
            // Translation Toggle
            SettingsToggleCard(
              title: 'Enable Translation',
              subtitle: 'Show translated lyrics if available.',
              value: provider.translationEnabled.current,
              onChanged: (value) => provider.setTranslationEnabled(value),
            ),
            if (provider.translationEnabled.current) ...[
              const SizedBox(height: 24),
              // Highlight Only
              SettingsToggleCard(
                title: 'Show Translation Only When Highlighted',
                subtitle: 'Hide translation for non-active lines.',
                value: provider.translationHighlightOnly.current,
                onChanged: (value) =>
                    provider.setTranslationHighlightOnly(value),
              ),
              const SizedBox(height: 24),
              // Target Language
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Language Code',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter language codes separated by commas. The app will try to find the first available translation in the specified order. Values are case-sensitive.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '* Musixmatch uses "zht" for Chinese (Traditional) and "zh" for Chinese (Simplified)',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '* LLM requires netural language input, use prefix "llm: [English]" to indicate the target language',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '* QQ Music and Netease Music only supports "zh_CN"',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: provider.translationTargetLanguages.current
                          .join(', '),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'e.g. en, zht, zh, jp',
                        hintStyle: TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      onChanged: (value) {
                        provider.setTranslationTargetLanguages(
                          value.isEmpty
                              ? []
                              : value
                                    .split(',')
                                    .map((e) => e.trim())
                                    .map(
                                      (e) => e.startsWith('llm:')
                                          ? 'llm: ${e.substring(4).trim()}' // normalize input with 'llm:' prefix
                                          : e,
                                    )
                                    .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bias
              SettingsSliderCard(
                title: 'Translation Bias',
                subtitle: 'Adjust timing of translation lines (ms).',
                value: provider.translationBias.current.toDouble(),
                min: 0,
                max: 1000,
                divisions: 20,
                label: '${provider.translationBias.current}ms',
                valueText: '${provider.translationBias.current}ms',
                onChanged: (value) =>
                    provider.setTranslationBias(value.toInt()),
                onReset: provider.translationBias.changed
                    ? () => provider.setTranslationBias(
                        provider.translationBias.defaultValue,
                      )
                    : null,
                resetTooltip: 'Reset to 50ms',
              ),
              const SizedBox(height: 24),
              // LLM Configuration
              LlmConfigurationCard(provider: provider),
            ],
          ],
        );
      },
    );
  }
}

class LlmConfigurationCard extends StatelessWidget {
  final LyricsProvider provider;

  const LlmConfigurationCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'LLM Configuration',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Endpoint
          TextFormField(
            initialValue: provider.llmApiEndpoint.current,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'API Endpoint',
              labelStyle: TextStyle(color: Colors.white54),
              hintText: 'https://api.openai.com/v1/chat/completions',
              hintStyle: TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
            ),
            onChanged: (value) => provider.setLlmApiEndpoint(value),
          ),
          const SizedBox(height: 12),
          // API Key
          TextFormField(
            initialValue: provider.llmApiKey.current,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'API Key',
              labelStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
            ),
            obscureText: true,
            onChanged: (value) => provider.setLlmApiKey(value),
          ),
          const SizedBox(height: 12),
          // Model
          TextFormField(
            initialValue: provider.llmModel.current,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Model Name',
              labelStyle: TextStyle(color: Colors.white54),
              hintText: 'openai/gpt-oss-120b',
              hintStyle: TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
            ),
            onChanged: (value) => provider.setLlmModel(value),
          ),
        ],
      ),
    );
  }
}
