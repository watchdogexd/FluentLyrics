class VersionDisplayHelper {
  const VersionDisplayHelper._();

  static String formatVersionLabel({
    required String version,
    required bool isDebugMode,
    required bool isProfileMode,
  }) {
    if (isDebugMode) {
      return '(dev, parent v$version)';
    }
    if (isProfileMode) {
      return '(profile, parent v$version)';
    }
    return 'v$version';
  }
}
