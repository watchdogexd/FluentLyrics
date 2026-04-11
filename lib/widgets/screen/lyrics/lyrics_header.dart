import 'package:flutter/material.dart';
import '../../../providers/lyrics_provider.dart';
import '../../../screens/settings_screen.dart';
import 'delayed_loading_image.dart';

class LyricsHeader extends StatelessWidget {
  final LyricsProvider provider;
  final ImageProvider artProvider;
  final VoidCallback onRefresh;
  final bool isLandscape;

  const LyricsHeader({
    super.key,
    required this.provider,
    required this.artProvider,
    required this.onRefresh,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLandscape) {
      return _buildLandscapeHeader(context);
    }
    return _buildPortraitHeader(context);
  }

  Widget _buildPortraitHeader(BuildContext context) {
    final metadata = provider.currentMetadata;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildArtThumb(artProvider),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata?.title ?? 'No Media Playing',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  metadata?.artist.join(', ') ?? 'Wait for music...',
                  style: TextStyle(
                    color: Colors.white.withAlpha(136),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white.withAlpha(200)),
            onPressed: onRefresh,
            tooltip: 'Clear cache & reload',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeHeader(BuildContext context) {
    final metadata = provider.currentMetadata;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Center(child: _buildArtThumb(artProvider, true)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata?.title ?? 'No Media Playing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata?.artist.join(', ') ?? 'Wait for music...',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white.withAlpha(200)),
                iconSize: 28,
                onPressed: onRefresh,
                tooltip: 'Clear cache & reload',
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                iconSize: 28,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtThumb(ImageProvider artImage, [bool large = false]) {
    return Container(
      width: large ? double.infinity : 64,
      height: large ? double.infinity : 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 24 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: large ? 24 : 12,
            offset: Offset(0, large ? 8 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(large ? 24 : 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double dpr = MediaQuery.of(context).devicePixelRatio;
            final int? cacheWidth = constraints.maxWidth.isFinite
                ? (constraints.maxWidth * dpr).round()
                : null;
            final int? cacheHeight = constraints.maxHeight.isFinite
                ? (constraints.maxHeight * dpr).round()
                : null;

            return DelayedLoadingImage(
              image: artImage,
              fit: BoxFit.cover,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading album art: $error');
                return Image.asset('assets/album_art.png', fit: BoxFit.cover);
              },
            );
          },
        ),
      ),
    );
  }
}
