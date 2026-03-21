import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../models/lyric_provider_type.dart';
import '../services/providers/musixmatch_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/screen/settings/settings_app_bar.dart';
import '../widgets/screen/settings/priority_section.dart';
import '../widgets/screen/settings/display_section.dart';
import '../widgets/screen/settings/translation_section.dart';
import '../widgets/screen/settings/lyric_configuration_section.dart';
import '../widgets/screen/settings/cache_section.dart';
import '../widgets/screen/settings/version_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final TextEditingController _tokenController = TextEditingController();

  List<LyricProviderType> _allProviders = [];
  int _enabledCount = 0;
  bool _cacheEnabled = true;
  bool _isLoading = true;
  bool _isFetchingToken = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final allProviders =
        (await _settingsService.getAllProvidersOrdered()).current;
    final enabledCount = (await _settingsService.getEnabledCount()).current;
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;
    final token = (await _settingsService.getMusixmatchToken()).current;
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _allProviders = allProviders;
      _enabledCount = enabledCount;
      _cacheEnabled = cacheEnabled;
      _tokenController.text = token ?? '';
      _version = packageInfo.version;
      _isLoading = false;
    });
  }

  Future<void> _savePriority() async {
    await _settingsService.setPriority(_allProviders);
    await _settingsService.setEnabledCount(_enabledCount);
    if (mounted) {
      _showSnackBar('Priority updated');
    }
  }

  Future<void> _toggleCache(bool enabled) async {
    setState(() => _cacheEnabled = enabled);
    await _settingsService.setCacheEnabled(enabled);
    if (mounted) {
      _showSnackBar(enabled ? 'Cache enabled' : 'Cache disabled');
    }
  }

  Future<void> _saveToken() async {
    await _settingsService.setMusixmatchToken(_tokenController.text);
    if (mounted) {
      _showSnackBar('Token saved');
    }
  }

  Future<void> _getNewToken() async {
    setState(() => _isFetchingToken = true);
    try {
      final newToken = await _musixmatchService.fetchNewToken();
      if (newToken != null) {
        setState(() {
          _tokenController.text = newToken;
        });
        await _settingsService.setMusixmatchToken(newToken);
        if (mounted) _showSnackBar('New token acquired');
      } else {
        if (mounted) _showSnackBar('Failed to get new token');
      }
    } finally {
      setState(() => _isFetchingToken = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        if (event.buttons == kBackMouseButton) {
          Navigator.pop(context);
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.pop(context),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1A1A), Colors.black],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsAppBar(
                        onBackPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PrioritySection(
                                      allProviders: _allProviders,
                                      enabledCount: _enabledCount,
                                      cacheEnabled: _cacheEnabled,
                                      onReorder:
                                          (newProviders, newEnabledCount) {
                                            setState(() {
                                              _allProviders = newProviders;
                                              _enabledCount = newEnabledCount;
                                            });
                                            _savePriority();
                                          },
                                      onCacheToggle: _toggleCache,
                                    ),
                                    const SizedBox(height: 48),
                                    const DisplaySection(),
                                    const SizedBox(height: 48),
                                    const TranslationSection(),
                                    const SizedBox(height: 48),
                                    LyricConfigurationSection(
                                      tokenController: _tokenController,
                                      isFetchingToken: _isFetchingToken,
                                      onGetNewToken: _getNewToken,
                                      onTokenChanged: _saveToken,
                                    ),
                                    const SizedBox(height: 48),
                                    CacheSection(
                                      onRefresh: () => setState(() {}),
                                      showSnackBar: _showSnackBar,
                                    ),
                                    const SizedBox(height: 48),
                                    VersionSection(version: _version),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
