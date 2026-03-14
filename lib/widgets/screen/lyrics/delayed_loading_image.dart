import 'dart:async';
import 'package:flutter/material.dart';

class DelayedLoadingImage extends StatefulWidget {
  final ImageProvider image;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const DelayedLoadingImage({
    super.key,
    required this.image,
    required this.fit,
    this.errorBuilder,
  });

  @override
  State<DelayedLoadingImage> createState() => _DelayedLoadingImageState();
}

class _DelayedLoadingImageState extends State<DelayedLoadingImage> {
  bool _showLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(DelayedLoadingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _showLoading = false;
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: widget.image,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          _timer?.cancel();
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (_showLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
