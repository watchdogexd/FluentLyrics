import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../models/lyric_model.dart';
import '../../../models/lyric_provider_type.dart';
import '../../../providers/lyrics_provider.dart';

/// Shows a modal bottom sheet that lists all lyric candidates collected during
/// the current auto-search. Lets the user choose one, which is then saved to
/// the Isar cache and applied immediately.
Future<void> showLyricsCandidateSheet(
  BuildContext context,
  LyricsProvider provider,
) {
  // If the fetch is paused waiting for this sheet, resume it now so remaining
  // providers are queried while the user browses the list.
  provider.resumeCandidateFetch();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LyricsCandidateSheet(provider: provider),
  );
}

class _LyricsCandidateSheet extends StatefulWidget {
  final LyricsProvider provider;
  const _LyricsCandidateSheet({required this.provider});

  @override
  State<_LyricsCandidateSheet> createState() => _LyricsCandidateSheetState();
}

class _LyricsCandidateSheetState extends State<_LyricsCandidateSheet> {
  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final candidates = provider.candidates;
    final current = provider.lyricsResult;

    return Listener(
      // Close on mouse back button.
      onPointerDown: (event) {
        if (event.buttons == kBackMouseButton) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          // Tapping the transparent area above the sheet dismisses it.
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.55, 0.92],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.library_music_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Choose Lyrics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (provider.isFetching)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white12, height: 16),

                    // Status bar — shows live onStatusUpdate messages while fetching
                    // after the candidate sheet opens and the stream resumes.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child:
                          provider.isFetching &&
                              provider.loadingStatus.isNotEmpty
                          ? Container(
                              key: const ValueKey('status'),
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Text(
                                provider.loadingStatus,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),

                    // Candidate list
                    Expanded(
                      child: candidates.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    color: Colors.white.withValues(alpha: 0.3),
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.isLoading
                                        ? 'Searching providers…'
                                        : 'No candidates found',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: candidates.length,
                              itemBuilder: (context, index) {
                                final candidate = candidates[index];
                                final isActive = _isActive(candidate, current);
                                return _CandidateTile(
                                  candidate: candidate,
                                  isActive: isActive,
                                  onSelect: () {
                                    provider.selectCandidate(candidate);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isActive(LyricsResult candidate, LyricsResult current) {
    // Match by source string (strip " (cached)" suffix for comparison).
    final candidateSrc = candidate.source.replaceAll(' (cached)', '');
    final currentSrc = current.source.replaceAll(' (cached)', '');
    return candidateSrc == currentSrc &&
        candidate.isSynced == current.isSynced &&
        candidate.isRichSync == current.isRichSync;
  }
}

class _CandidateTile extends StatelessWidget {
  final LyricsResult candidate;
  final bool isActive;
  final VoidCallback onSelect;

  const _CandidateTile({
    required this.candidate,
    required this.isActive,
    required this.onSelect,
  });

  /// Try to map source string to provider type for badge colour.
  LyricProviderType? _providerType() {
    final src = candidate.source.toLowerCase();
    if (src.contains('lrclib')) return LyricProviderType.lrclib;
    if (src.contains('musixmatch')) return LyricProviderType.musixmatch;
    if (src.contains('netease')) return LyricProviderType.netease;
    if (src.contains('qq')) return LyricProviderType.qqmusic;
    if (src.contains('cache')) return LyricProviderType.cache;
    return null;
  }

  String _syncLabel() {
    if (candidate.isPureMusic) return 'Instrumental';
    if (candidate.isRichSync) return 'Rich Sync';
    if (candidate.isSynced) return 'Synced';
    return 'Plain';
  }

  IconData _syncIcon() {
    if (candidate.isPureMusic) return Icons.music_note_rounded;
    if (candidate.isRichSync) return Icons.auto_awesome_rounded;
    if (candidate.isSynced) return Icons.timer_rounded;
    return Icons.notes_rounded;
  }

  Color _syncColor() {
    if (candidate.isPureMusic) return Colors.purple;
    if (candidate.isRichSync) return Colors.amber;
    if (candidate.isSynced) return Colors.lightBlue;
    return Colors.grey;
  }

  String _preview() {
    final lines = candidate.lyrics
        .where((l) => l.text.trim().isNotEmpty)
        .take(2)
        .map((l) => l.text.trim())
        .join('  /  ');
    return lines.isEmpty ? '(no lyrics)' : lines;
  }

  @override
  Widget build(BuildContext context) {
    final providerType = _providerType();
    final providerColor = providerType != null
        ? (providerType.metadata['color'] as Color)
        : Colors.grey;
    final providerName = candidate.source;

    return GestureDetector(
      onTap: isActive ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: badges + active checkmark
              Row(
                children: [
                  // Provider badge
                  _Badge(label: providerName, color: providerColor),
                  const SizedBox(width: 6),
                  // Sync-type badge
                  _Badge(
                    label: _syncLabel(),
                    icon: _syncIcon(),
                    color: _syncColor(),
                  ),
                  const Spacer(),
                  if (isActive)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Lyric preview
              Text(
                _preview(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Optional: line count
              const SizedBox(height: 6),
              Text(
                candidate.isPureMusic
                    ? 'Instrumental track'
                    : '${candidate.lyrics.length} lines',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
