import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../models/lyric_model.dart';
import '../../../providers/lyrics_provider.dart';
import '../../lyric_line.dart';
import '../../interlude_indicator.dart';

class LyricsList extends StatelessWidget {
  final LyricsProvider provider;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final bool isManualScrolling;
  final Function(int) onUserInteraction;

  const LyricsList({
    super.key,
    required this.provider,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isManualScrolling,
    required this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              provider.loadingStatus.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.lyrics.isEmpty) {
      String message = 'No lyrics found for this track';
      if (provider.currentMetadata == null) {
        message = 'Start playing music';
      } else if (provider.lyricsResult.isPureMusic) {
        message = 'Pure Music / Instrumental';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle) {
          onUserInteraction(provider.scrollAutoResumeDelay.current);
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        itemCount: provider.lyrics.length + 1,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemBuilder: (context, index) {
          // Metadata Line
          if (index == provider.lyrics.length) {
            return _buildLyricsInfoLine(provider.lyricsResult);
          }

          // Lyric Lines
          final lyric = provider.lyrics[index];
          final isHighlighted = index == provider.currentIndex;
          final distance = (index - provider.currentIndex).toDouble();

          final lyricLine = LyricLine(
            lyric: lyric,
            isHighlighted: isHighlighted,
            distance: distance,
            isManualScrolling: isManualScrolling,
            blurEnabled: provider.blurEnabled.current,
          );

          Widget content = lyricLine;

          // Handle Interludes (empty lines, now including injected prelude)
          if (isHighlighted &&
              provider.isInterlude &&
              lyric.text.trim().isEmpty) {
            content = InterludeIndicator(
              progress: provider.interludeProgress,
              duration: provider.interludeDuration,
            );
          }

          return GestureDetector(
            onDoubleTap: provider.controlAbility.canSeek
                ? () => provider.seek(lyric.startTime)
                : null,
            behavior: HitTestBehavior.translucent,
            child: content,
          );
        },
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height / 3,
        ),
      ),
    );
  }

  Widget _buildLyricsInfoLine(LyricsResult result) {
    final List<String> infoParts = [];
    if (result.source.isNotEmpty) {
      infoParts.add('Source: ${result.source}');
    }
    if (result.writtenBy != null && result.writtenBy!.isNotEmpty) {
      infoParts.add('Written by: ${result.writtenBy}');
    }
    if (result.composer != null && result.composer!.isNotEmpty) {
      infoParts.add('Composer: ${result.composer}');
    }
    if (result.contributor != null && result.contributor!.isNotEmpty) {
      infoParts.add('Contributor: ${result.contributor}');
    }
    if (result.copyright != null && result.copyright!.isNotEmpty) {
      infoParts.add('Copyright: ${result.copyright}');
    }
    if (result.subLyrics != null &&
        result.subLyrics!.translationProvider != null &&
        result.subLyrics!.translationProvider!.isNotEmpty) {
      infoParts.add(
        'Translation Provider: ${result.subLyrics!.translationProvider}',
      );
    }
    if (result.subLyrics != null &&
        result.subLyrics!.translationContributor != null &&
        result.subLyrics!.translationContributor!.isNotEmpty) {
      infoParts.add(
        'Translation Contributor: ${result.subLyrics!.translationContributor}',
      );
    }

    if (infoParts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 48, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: infoParts
            .map(
              (info) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  info,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
