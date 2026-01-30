import 'package:flutter/material.dart';

/// Official Apple icon
/// 
/// To use the official Apple icon:
/// 1. Download the official Apple icon from:
///    https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
/// 2. Save it as 'apple_icon.png' in assets/images/
/// 3. The icon should be white/light colored for dark backgrounds
class AppleIcon extends StatelessWidget {
  const AppleIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/apple_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: Simple Apple icon if image not found
          return Icon(
            Icons.apple,
            size: size,
            color: Colors.white,
          );
        },
      ),
    );
  }
}
