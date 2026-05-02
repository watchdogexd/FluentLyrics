import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_card_frame.dart';
import '../../../utils/cache_helper.dart';

class CacheSection extends StatefulWidget {
  final VoidCallback onRefresh;
  final Function(String message) showSnackBar;

  const CacheSection({
    super.key,
    required this.onRefresh,
    required this.showSnackBar,
  });

  @override
  State<CacheSection> createState() => _CacheSectionState();
}

class _CacheSectionState extends State<CacheSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Cache Management',
      description: 'Manage local storage for lyrics.',
      children: [
        SettingsCardFrame(
          child: Consumer<LyricsProvider>(
            builder: (context, provider, child) {
              return _CacheActionCard(
                title: 'Lyrics Cache',
                description:
                    'Clearing the cache will force the app to search for lyrics again.',
                stats: FutureBuilder<Map<String, dynamic>>(
                  future: provider.getCacheStats(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final count = snapshot.data!['count'];
                      final size = snapshot.data!['size'];
                      return Text(
                        '$count items, ${CacheHelper.formatSize(size)} (Est.)',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                actionButton: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text(
                          'Clear Cache',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to clear all cached lyrics?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'CLEAR ALL',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await provider.clearAllCache();
                      if (mounted) {
                        setState(() {});
                        widget.onRefresh();
                        widget.showSnackBar('Cache cleared');
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text(
                    'Clear All Lyrics Cache',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SettingsCardFrame(
          child: _CacheActionCard(
            title: 'Artwork Cache',
            description:
                'Clearing the cache will force the app to download artwork again.',
            stats: FutureBuilder<Map<String, int>>(
              future: CacheHelper.getArtworkCacheStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final count = snapshot.data!['count']!;
                  final size = snapshot.data!['size']!;
                  return Text(
                    '$count items, ${CacheHelper.formatSize(size)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            actionButton: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      'Clear Artwork Cache',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to clear all cached artwork?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'CLEAR ALL',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await CacheHelper.clearArtworkCache();
                  if (mounted) {
                    setState(() {});
                    widget.onRefresh();
                    widget.showSnackBar('Artwork cache cleared');
                  }
                }
              },
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text(
                'Clear All Artwork Cache',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CacheActionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget stats;
  final Widget actionButton;

  const _CacheActionCard({
    required this.title,
    required this.description,
    required this.stats,
    required this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            stats,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [Expanded(child: actionButton)],
        ),
      ],
    );
  }
}
