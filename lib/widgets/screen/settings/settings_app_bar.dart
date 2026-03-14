import 'package:flutter/material.dart';

class SettingsAppBar extends StatelessWidget {
  final VoidCallback onBackPressed;

  const SettingsAppBar({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onBackPressed,
          ),
          const SizedBox(width: 8),
          const Text(
            'Lyrics Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
