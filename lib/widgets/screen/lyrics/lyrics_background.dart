import 'dart:ui';
import 'package:flutter/material.dart';

class LyricsBackground extends StatelessWidget {
  final ImageProvider artProvider;

  const LyricsBackground({super.key, required this.artProvider});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey(artProvider),
        decoration: BoxDecoration(
          image: DecorationImage(image: artProvider, fit: BoxFit.cover),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.black.withAlpha(136)),
        ),
      ),
    );
  }
}
