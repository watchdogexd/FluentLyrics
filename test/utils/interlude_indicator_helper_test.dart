import 'package:fluent_lyrics/utils/interlude_indicator_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isSwellPhase returns false for non-positive durations', () {
    expect(
      InterludeIndicatorHelper.isSwellPhase(
        progress: 0.5,
        duration: Duration.zero,
      ),
      isFalse,
    );
  });

  test('targetScale stays at one before swell window', () {
    expect(
      InterludeIndicatorHelper.targetScale(
        progress: 0.1,
        duration: const Duration(seconds: 5),
      ),
      1.0,
    );
  });

  test('targetScale swells during swell phase', () {
    final scale = InterludeIndicatorHelper.targetScale(
      progress: 0.9,
      duration: const Duration(seconds: 5),
    );

    expect(scale, greaterThan(1.0));
    expect(scale, lessThanOrEqualTo(InterludeIndicatorHelper.swellScale));
  });

  test('dotProgress offsets each later dot', () {
    final duration = const Duration(seconds: 5);

    final firstDot = InterludeIndicatorHelper.dotProgress(
      progress: 0.2,
      dotIndex: 0,
      duration: duration,
    );
    final secondDot = InterludeIndicatorHelper.dotProgress(
      progress: 0.2,
      dotIndex: 1,
      duration: duration,
    );

    expect(firstDot, greaterThan(secondDot));
  });

  test('dotDurationForDuration returns zero for non-positive durations', () {
    expect(
      InterludeIndicatorHelper.dotDurationForDuration(Duration.zero),
      Duration.zero,
    );
  });
}
