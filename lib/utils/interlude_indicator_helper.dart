class InterludeIndicatorHelper {
  const InterludeIndicatorHelper._();

  static const int shrinkDurationMs = 200;
  static const int swellDurationMs = 250;
  static const double overlap = 0.3;
  static const double swellScale = 1.15;

  static bool isSwellPhase({
    required double progress,
    required Duration duration,
  }) {
    if (duration.inMilliseconds <= 0) return false;
    final totalDotWindow = totalDotWindowForDuration(duration);
    final swellStart =
        totalDotWindow - (swellDurationMs / duration.inMilliseconds);
    return progress >= swellStart && progress < totalDotWindow;
  }

  static double totalDotWindowForDuration(Duration duration) {
    return 1 - ((shrinkDurationMs + 150) / duration.inMilliseconds);
  }

  static Duration dotDurationForDuration(Duration duration) {
    if (duration.inMilliseconds <= 0) return Duration.zero;
    final totalDotWindow = totalDotWindowForDuration(duration);
    final step = 1 - overlap;
    final d = totalDotWindow / (2 * step + 1);
    return Duration(
      milliseconds: (d * totalDotWindow * duration.inMilliseconds).round(),
    );
  }

  static double targetScale({
    required double progress,
    required Duration duration,
  }) {
    final totalDotWindow = totalDotWindowForDuration(duration);
    final swellStart =
        totalDotWindow - (swellDurationMs / duration.inMilliseconds);

    if (progress >= totalDotWindow) {
      return ((1.0 - progress) / (1.0 - totalDotWindow)).clamp(0.0, 1.0) *
          swellScale;
    }

    if (progress >= swellStart) {
      final swellProgress =
          (progress - swellStart) / (totalDotWindow - swellStart);
      return 1.0 + (swellScale - 1.0) * swellProgress.clamp(0.0, 1.0);
    }

    return 1.0;
  }

  static double dotProgress({
    required double progress,
    required int dotIndex,
    required Duration duration,
  }) {
    final totalDotWindow = totalDotWindowForDuration(duration);
    final step = 1 - overlap;
    final d = totalDotWindow / (2 * step + 1);
    return ((progress - (dotIndex * step * d)) / d).clamp(0.0, 1.0);
  }
}
