import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie illustration with fallback for pre-login intro.
class IntroLottie extends StatelessWidget {
  const IntroLottie({
    super.key,
    required this.assetPath,
    this.size = 220,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Lottie.asset(
          assetPath,
          fit: BoxFit.contain,
          repeat: true,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Icon(
      Icons.smart_toy_rounded,
      size: size * 0.6,
      color: Colors.white.withOpacity(0.6),
    );
  }
}
