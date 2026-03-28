import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class LyricsBackground extends StatelessWidget {
  final ImageProvider artProvider;
  final bool motionEnabled;

  const LyricsBackground({
    super.key,
    required this.artProvider,
    this.motionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: motionEnabled
          ? _FragmentedBackground(
              key: ValueKey(('fragmented', artProvider)),
              artProvider: artProvider,
            )
          : _StaticBackground(
              key: ValueKey(('static', artProvider)),
              artProvider: artProvider,
            ),
    );
  }
}

/// Original static blurred background.
class _StaticBackground extends StatelessWidget {
  final ImageProvider artProvider;

  const _StaticBackground({super.key, required this.artProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: artProvider, fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.black.withAlpha(136)),
      ),
    );
  }
}

/// Fragmented background with slow drifting motion.
class _FragmentedBackground extends StatefulWidget {
  final ImageProvider artProvider;

  const _FragmentedBackground({super.key, required this.artProvider});

  @override
  State<_FragmentedBackground> createState() => _FragmentedBackgroundState();
}

class _FragmentedBackgroundState extends State<_FragmentedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Fragment> _fragments;
  static const int _fragmentCount = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    _fragments = _generateFragments();
  }

  List<_Fragment> _generateFragments() {
    final rng = Random(widget.artProvider.hashCode);
    return List.generate(_fragmentCount, (i) {
      return _Fragment(
        // Normalised position (0..1) – spread widely
        baseX: rng.nextDouble() * 1.4 - 0.2,
        baseY: rng.nextDouble() * 1.4 - 0.2,
        // Large scale so fragments overlap and cover the canvas
        scale: 0.7 + rng.nextDouble() * 0.6,
        // Each fragment drifts in its own direction
        driftX: (rng.nextDouble() - 0.5) * 0.08,
        driftY: (rng.nextDouble() - 0.5) * 0.06,
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.3,
        // Phase offset so they don't all sync up
        phase: rng.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _FragmentedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artProvider != widget.artProvider) {
      _fragments = _generateFragments();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base dark layer
              Container(color: Colors.black),

              // Fragmented image layers
              for (final frag in _fragments)
                _buildFragment(frag, _controller.value),

              // Blur + dark scrim on top
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.black.withAlpha(136)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFragment(_Fragment frag, double t) {
    final angle = t * 2 * pi;
    // Smooth sinusoidal drift
    final dx = frag.driftX * sin(angle + frag.phase);
    final dy = frag.driftY * cos(angle * 0.7 + frag.phase);
    final rot = frag.rotation + frag.rotationSpeed * sin(angle + frag.phase);

    return Positioned.fill(
      child: FractionalTranslation(
        translation: Offset(frag.baseX - 0.5 + dx, frag.baseY - 0.5 + dy),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(rot)
            ..scale(frag.scale),
          child: Opacity(
            opacity: 0.7,
            child: Image(
              image: widget.artProvider,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fragment {
  final double baseX;
  final double baseY;
  final double scale;
  final double driftX;
  final double driftY;
  final double rotation;
  final double rotationSpeed;
  final double phase;

  const _Fragment({
    required this.baseX,
    required this.baseY,
    required this.scale,
    required this.driftX,
    required this.driftY,
    required this.rotation,
    required this.rotationSpeed,
    required this.phase,
  });
}
