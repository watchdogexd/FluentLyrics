import 'package:flutter/material.dart';

enum LyricProviderType { lrclib, musixmatch, netease, qqmusic, cache, llm }

extension LyricProviderTypeMetadata on LyricProviderType {
  Map<String, dynamic> get metadata {
    switch (this) {
      case LyricProviderType.lrclib:
        return {
          'color': Colors.blue,
          'name': 'LRCLIB',
          'description': 'Open-source lyrics database',
        };
      case LyricProviderType.musixmatch:
        return {
          'color': Colors.orange,
          'name': 'Musixmatch',
          'description': 'World\'s largest lyrics catalog',
        };
      case LyricProviderType.netease:
        return {
          'color': Colors.red,
          'name': 'Netease Music',
          'description':
              'Chinese music service, community driven lyrics catalog',
        };
      case LyricProviderType.qqmusic:
        return {
          'color': Colors.green,
          'name': 'QQ Music',
          'description': 'Chinese music streaming service by Tencent',
        };
      case LyricProviderType.llm:
        return {
          'color': Colors.purple,
          'name': 'LLM Traslation',
          'description': 'OpenAI compatible LLM API',
        };
      case LyricProviderType.cache:
        return {
          'color': Colors.grey,
          'name': 'Cache',
          'description': 'Cached lyrics',
        };
    }
  }
}

