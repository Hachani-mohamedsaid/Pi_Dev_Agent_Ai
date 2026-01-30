import 'package:flutter/material.dart';

/// Official Google "G" icon
/// 
/// To use the official Google icon:
/// 1. Download the official Google "G" icon from:
///    https://developers.google.com/identity/branding-guidelines
/// 2. Save it as 'google_icon.png' in assets/images/
/// 3. The icon should be white/light colored for dark backgrounds
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/google_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: Simple "G" text if image not found
          return Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.7,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          );
        },
      ),
    );
  }
}
