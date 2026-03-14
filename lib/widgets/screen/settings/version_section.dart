import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class VersionSection extends StatelessWidget {
  final String version;

  const VersionSection({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final versionDisplay = kDebugMode ? '(dev, parent v$version)' : 'v$version';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Fluent Lyrics $versionDisplay',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
