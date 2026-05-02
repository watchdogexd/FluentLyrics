import 'package:fluent_lyrics/utils/version_display_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats debug label', () {
    expect(
      VersionDisplayHelper.formatVersionLabel(
        version: '1.2.3',
        isDebugMode: true,
        isProfileMode: false,
      ),
      '(dev, parent v1.2.3)',
    );
  });

  test('formats profile label', () {
    expect(
      VersionDisplayHelper.formatVersionLabel(
        version: '1.2.3',
        isDebugMode: false,
        isProfileMode: true,
      ),
      '(profile, parent v1.2.3)',
    );
  });

  test('formats release label', () {
    expect(
      VersionDisplayHelper.formatVersionLabel(
        version: '1.2.3',
        isDebugMode: false,
        isProfileMode: false,
      ),
      'v1.2.3',
    );
  });
}
