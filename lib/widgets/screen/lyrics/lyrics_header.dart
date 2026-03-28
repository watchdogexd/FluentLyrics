import 'package:flutter/material.dart';
import '../../../providers/lyrics_provider.dart';
import '../../../screens/settings_screen.dart';
import 'delayed_loading_image.dart';

class LyricsHeader extends StatelessWidget {
  final LyricsProvider provider;
  final ImageProvider artProvider;
  final VoidCallback onRefresh;

  const LyricsHeader({
    super.key,
    required this.provider,
    required this.artProvider,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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

  Widget _buildArtThumb(ImageProvider artImage) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DelayedLoadingImage(
          image: artImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading album art: $error');
            return Image.asset('assets/album_art.png', fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}
