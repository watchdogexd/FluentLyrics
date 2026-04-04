import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lyric_model.dart';
import '../providers/lyrics_provider.dart';

class LyricLine extends StatelessWidget {
  final Lyric lyric;
  final bool isHighlighted;
  final double distance; // 0 is current, 1 is adjacent, etc.
  final bool isManualScrolling;
  final bool blurEnabled;
  final bool inViewport;

  const LyricLine({
    super.key,
    required this.lyric,
    required this.isHighlighted,
    this.distance = 0,
    this.isManualScrolling = false,
    this.blurEnabled = true,
    this.inViewport = true,
  });

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final fontSize = lyricsProvider.fontSize.current;
    final inactiveScale = lyricsProvider.inactiveScale.current;

    const double minOpacity = 0.4;

    // Calculate opacity and blur based on distance
    // Current line (distance 0) has full opacity and no blur.
    // Further lines fade and blur out.
    final double opacity = !inViewport
        ? minOpacity
        : isHighlighted
        ? 1.0
        : (isManualScrolling
              ? 0.55
              : (minOpacity / (distance.abs() * 0.5 + 1)).clamp(
                  0.05,
                  minOpacity,
                ));
    final double blur = !inViewport
        ? 0.0
        : (isHighlighted || isManualScrolling || !blurEnabled)
        ? 0.0
        : (distance.abs() * 1.5).clamp(0.0, 4.0);

    TextStyle lineStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: fontSize,
      fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
      color: Colors.white,
      height: 1.2,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.symmetric(
        vertical: isHighlighted ? 18 : 12,
        horizontal: 24,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        opacity: opacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuart,
            scale: isHighlighted ? 1.0 : inactiveScale,
            alignment: Alignment.centerLeft,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              style: lineStyle,
              child: Builder(
                builder: (context) {
                  final mainText = _buildText(context, lyricsProvider);
                  if (lyric.translation == null ||
                      (lyricsProvider.translationHighlightOnly.current &&
                          !isHighlighted)) {
                    return mainText;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      mainText,
                      isHighlighted ||
                              !lyricsProvider.translationHighlightOnly.current
                          ? const SizedBox(width: double.infinity, height: 8)
                          : const SizedBox(width: double.infinity, height: 0),
                      isHighlighted ||
                              !lyricsProvider.translationHighlightOnly.current
                          ? AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutQuart,
                              opacity: 1.0,
                              child: Builder(
                                builder: (context) {
                                  final style = DefaultTextStyle.of(
                                    context,
                                  ).style;
                                  return Text(
                                    lyric.translation!,
                                    style: style.copyWith(
                                      fontSize: (style.fontSize! * 0.65)
                                          .roundToDouble(),
                                      height: 1.2,
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                    textAlign: TextAlign.left,
                                  );
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context, LyricsProvider lyricsProvider) {
    final text = lyric.text;
    if (!isHighlighted ||
        lyric.inlineParts == null ||
        lyric.inlineParts!.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.left,
        style: DefaultTextStyle.of(context).style,
      );
    } else if (lyric.inlineParts!.length == 1) {
      return Text(
        lyric.inlineParts!.first.text,
        textAlign: TextAlign.left,
        style: DefaultTextStyle.of(context).style,
      );
    }

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: lyric.inlineParts!.map<InlineSpan>((part) {
          if (part.text.trim().isEmpty) {
            return TextSpan(
              text: part.text,
              style: DefaultTextStyle.of(context).style,
            );
          }
          return WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _RichPart(
              text: part.text,
              startTime: part.startTime,
              endTime: part.endTime,
              style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: DefaultTextStyle.of(context).style.fontSize!,
              ),
            ),
          );
        }).toList(),
      ),
      textAlign: TextAlign.left,
    );
  }
}

class _RichPart extends StatefulWidget {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final TextStyle style;

  const _RichPart({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.style,
  });

  @override
  State<_RichPart> createState() => _RichPartState();
}

class _RichPartState extends State<_RichPart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const Duration _defaultProgressAnimationDuration = Duration(
    milliseconds: 350,
  );
  static const Duration _progressAnimationThreshold = Duration(
    milliseconds: 800,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.endTime - widget.startTime,
    );
  }

  @override
  void didUpdateWidget(_RichPart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endTime - widget.startTime !=
        oldWidget.endTime - oldWidget.startTime) {
      _controller.duration = widget.endTime - widget.startTime;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final adjustedPosition =
        lyricsProvider.currentPosition +
        lyricsProvider.globalOffset +
        lyricsProvider.trackOffset;

    final duration = widget.endTime - widget.startTime;

    // Synchronize controller with song position
    if (adjustedPosition < widget.startTime) {
      if (_controller.value != 0) _controller.value = 0;
    } else if (adjustedPosition >= widget.endTime) {
      if (_controller.value != 1) _controller.value = 1;
    } else {
      final durationMs = duration.inMilliseconds;
      if (durationMs > 0) {
        final double targetProgress =
            (adjustedPosition - widget.startTime).inMilliseconds / durationMs;
        if (!lyricsProvider.isPlaying) {
          if ((_controller.value - targetProgress).abs() > 0.01) {
            _controller.value = targetProgress;
          }
          if (_controller.isAnimating) _controller.stop();
        } else {
          final double diffMs =
              ((_controller.value - targetProgress) * durationMs).abs();
          // Snap only if we just started, or if we significantly drifted (e.g., buffering/seeking)
          if (_controller.value == 0.0 || diffMs > 400) {
            _controller.value = targetProgress;
          }

          if (!_controller.isAnimating && _controller.value < 1.0) {
            _controller.forward();
          }
        }
      } else {
        _controller.value = 1.0;
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final bool isLifting = progress > 0;
        final bool isShort =
            duration < _progressAnimationThreshold ||
            (widget.text.length <= 1 &&
                widget.text.contains(
                  RegExp(r'[\p{P}\p{S}]', unicode: true),
                )); // check for punctuation

        return AnimatedContainer(
          duration: isShort
              ? _defaultProgressAnimationDuration
              : duration + Duration(milliseconds: 150),
          curve: Curves.easeOutQuint,
          transform: Matrix4.translationValues(0, isLifting ? -2 : 0, 0),
          child: Stack(
            children: [
              Text(
                widget.text,
                textAlign: TextAlign.left,
                style: widget.style.copyWith(
                  color: Colors.white.withValues(
                    alpha: (isShort && isLifting) ? 1 : 0.4,
                  ),
                ),
              ),
              if (isLifting && !isShort)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _KaraokeTextPainter(
                      text: widget.text,
                      style: widget.style,
                      progress: progress,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KaraokeTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double progress;
  final TextScaler textScaler;

  _KaraokeTextPainter({
    required this.text,
    required this.style,
    required this.progress,
    required this.textScaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );

    textPainter.layout(maxWidth: size.width);

    final lines = textPainter.computeLineMetrics();
    final totalWidth = lines.fold(0.0, (sum, line) => sum + line.width);

    final double fadeWidth = totalWidth * 0.15;
    final double pRight = totalWidth * progress * (1 + 0.15);
    final double pLeft = pRight - fadeWidth;

    canvas.saveLayer(Offset.zero & size, Paint());
    textPainter.paint(canvas, Offset.zero);

    final maskPaint = Paint()..blendMode = BlendMode.dstIn;
    canvas.saveLayer(Offset.zero & size, maskPaint);

    double lineStart = 0.0;
    double y = 0.0;

    for (final line in lines) {
      final double localLeft = pLeft - lineStart;
      final double localRight = pRight - lineStart;

      final gradientPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(localLeft, 0),
          Offset(localRight, 0),
          [Colors.white, Colors.white.withValues(alpha: 0.0)],
          [0.0, 1.0],
        );

      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, line.height),
        gradientPaint,
      );

      lineStart += line.width;
      y += line.height;
    }

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KaraokeTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.progress != progress ||
        oldDelegate.textScaler != textScaler;
  }
}
