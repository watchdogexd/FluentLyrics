import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/lyrics_provider.dart';
import '../services/media_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../widgets/screen/lyrics/lyrics_background.dart';
import '../widgets/screen/lyrics/lyrics_header.dart';
import '../widgets/screen/lyrics/lyrics_list.dart';
import '../widgets/screen/lyrics/lyrics_control_area.dart';
import '../widgets/screen/lyrics/permission_overlay.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final Set<String> _failedArtUrls = {};
  int _previousIndex = 0;
  String? _lastArtUrl;
  ImageProvider? _foregroundArtProvider;
  ImageProvider? _backgroundArtProvider;
  bool _isManualScrolling = false;
  Timer? _autoResumeTimer;
  String? _lastTitle;
  String? _lastArtist;
  bool _isForceReloading = false;
  bool _isScrubbing = false;
  double _scrubValue = 0.0;

  void _scrollToCurrentIndex(int index, int linesBefore) {
    if (_itemScrollController.isAttached) {
      final safeIndex = index < 0 ? 0 : index;
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;

      final targetIndex = isLandscape
          ? safeIndex
          : (safeIndex - linesBefore).clamp(0, safeIndex);
      final alignment = isLandscape ? 0.3 : 0.0;

      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
        alignment: alignment,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        // Wakelock logic (Android only)
        if (Platform.isAndroid) {
          if (provider.keepScreenOn.current) {
            WakelockPlus.enable();
          } else {
            WakelockPlus.disable();
          }
        }

        // Auto-scroll logic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.currentIndex != _previousIndex) {
            if (!_isManualScrolling) {
              _scrollToCurrentIndex(
                provider.currentIndex,
                provider.linesBefore.current,
              );
            }
            _previousIndex = provider.currentIndex;
          }
        });

        final metadata = provider.currentMetadata;
        _updateArtProviders(
          metadata,
          provider.mediaService,
          provider.artworkUrlsNotifier.value,
          forceReload: _isForceReloading,
        );
        if (_isForceReloading) _isForceReloading = false;

        final bgArt =
            _backgroundArtProvider ??
            _foregroundArtProvider ??
            const AssetImage('assets/album_art.png');
        final fgArt =
            _foregroundArtProvider ?? const AssetImage('assets/album_art.png');

        return Scaffold(
          body: Stack(
            children: [
              // Background Layer
              LyricsBackground(
                artProvider: bgArt,
                motionEnabled: provider.backgroundMotionEnabled.current,
              ),

              // Content Layer
              SafeArea(
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    final isLandscape = orientation == Orientation.landscape;

                    Future<void> onRefresh() async {
                      setState(() {
                        _isForceReloading = true;
                        _lastArtUrl = null;
                        _failedArtUrls.clear();
                      });
                      if (_foregroundArtProvider != null) {
                        _foregroundArtProvider!.evict();
                      }
                      if (_backgroundArtProvider != null) {
                        _backgroundArtProvider!.evict();
                      }
                      await provider.clearCurrentTrackCache();
                    }

                    ;

                    final lyricsListWidget = ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.05, 0.95, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: LyricsList(
                          provider: provider,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          isManualScrolling: _isManualScrolling,
                          onUserInteraction: _handleUserInteraction,
                        ),
                      ),
                    );

                    final controlAreaWidget = LyricsControlArea(
                      provider: provider,
                      isScrubbing: _isScrubbing,
                      scrubValue: _scrubValue,
                      onScrubChanged: (value) {
                        setState(() {
                          _isScrubbing = true;
                          _scrubValue = value;
                        });
                      },
                      onScrubEnd: (value) {
                        final totalMs =
                            provider.currentMetadata?.duration.inMilliseconds ??
                            1;
                        final ms = (value * totalMs).round();
                        provider.seek(Duration(milliseconds: ms));
                        setState(() {
                          _isScrubbing = false;
                        });
                      },
                    );

                    if (isLandscape) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 48.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: LyricsHeader(
                                          provider: provider,
                                          artProvider: fgArt,
                                          isLandscape: true,
                                          onRefresh: onRefresh,
                                        ),
                                      ),
                                      controlAreaWidget,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(flex: 1, child: lyricsListWidget),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        LyricsHeader(
                          provider: provider,
                          artProvider: fgArt,
                          onRefresh: onRefresh,
                        ),
                        Expanded(child: lyricsListWidget),
                        controlAreaWidget,
                      ],
                    );
                  },
                ),
              ),
              // Permission Overlay
              PermissionOverlay(provider: provider),
            ],
          ),
        );
      },
    );
  }

  void _updateArtProviders(
    MediaMetadata? metadata,
    MediaService mediaService,
    List<String> alternateUrls, {
    bool forceReload = false,
  }) {
    String? artUrl = metadata?.artUrl.trim();
    final title = metadata?.title;
    final artist = metadata?.artist.join(', ');

    if (title != _lastTitle || artist != _lastArtist) {
      _failedArtUrls.clear();
    }

    if (artUrl != null && _failedArtUrls.contains(artUrl)) {
      artUrl = 'fallback';
    }

    if (artUrl == null || artUrl.isEmpty || artUrl == 'fallback') {
      for (final url in alternateUrls) {
        if (!_failedArtUrls.contains(url)) {
          artUrl = url;
          break;
        }
      }
    }

    final hasValidArt =
        artUrl != null && artUrl.isNotEmpty && artUrl != 'fallback';

    if (hasValidArt && metadata != null) {
      if (artUrl != _lastArtUrl || forceReload) {
        _lastArtUrl = artUrl;
        _foregroundArtProvider = _getArtProvider(artUrl, mediaService);
        _precacheAndSwap(_foregroundArtProvider!, artUrl);
      }
    } else {
      if (!forceReload && title == _lastTitle && artist == _lastArtist) {
        // Keep current
      } else {
        if (metadata == null) {
          _lastArtUrl = null;
          _foregroundArtProvider = const AssetImage('assets/album_art.png');
          _backgroundArtProvider = _foregroundArtProvider;
        } else {
          _lastArtUrl = artUrl;
        }
      }
    }

    _lastTitle = title;
    _lastArtist = artist;
  }

  void _precacheAndSwap(ImageProvider provider, String url) {
    precacheImage(provider, context)
        .then((_) {
          if (mounted && _lastArtUrl == url) {
            setState(() {
              _backgroundArtProvider = provider;
            });
          }
        })
        .catchError((e) {
          if (mounted && _lastArtUrl == url) {
            setState(() {
              _failedArtUrls.add(url);
            });
          }
        });
  }

  ImageProvider _getArtProvider(String? artUrl, MediaService mediaService) {
    if (artUrl == null || artUrl.isEmpty || artUrl == 'fallback') {
      return const AssetImage('assets/album_art.png');
    }

    if (artUrl.startsWith('data:')) {
      final commaIndex = artUrl.indexOf(',');
      if (commaIndex != -1) {
        try {
          final base64String = artUrl
              .substring(commaIndex + 1)
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .trim();
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          return const AssetImage('assets/album_art.png');
        }
      }
    }

    if (artUrl.startsWith('file://')) {
      try {
        return FileImage(File(Uri.parse(artUrl).toFilePath()));
      } catch (e) {
        return const AssetImage('assets/album_art.png');
      }
    }

    if (artUrl.startsWith('/')) {
      try {
        return FileImage(File(artUrl));
      } catch (e) {
        return const AssetImage('assets/album_art.png');
      }
    }

    try {
      return CachedNetworkImageProvider(artUrl);
    } catch (e) {
      return const AssetImage('assets/album_art.png');
    }
  }

  void _handleUserInteraction(int delaySeconds) {
    if (delaySeconds == 0) return;

    if (!_isManualScrolling) {
      setState(() {
        _isManualScrolling = true;
      });
    }

    _autoResumeTimer?.cancel();
    _autoResumeTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) {
        setState(() {
          _isManualScrolling = false;
        });
        final provider = Provider.of<LyricsProvider>(context, listen: false);
        _scrollToCurrentIndex(
          provider.currentIndex,
          provider.linesBefore.current,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoResumeTimer?.cancel();
    if (Platform.isAndroid) {
      WakelockPlus.disable();
    }
    super.dispose();
  }
}
