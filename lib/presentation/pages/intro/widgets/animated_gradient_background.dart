import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Slowly animated gradient background (10–20s loop).
/// Subtle and non-distracting.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        final cx = 0.5 + 0.15 * math.cos(t);
        final cy = 0.4 + 0.12 * math.sin(t * 0.7);
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(cx * 2 - 1, cy * 2 - 1),
              radius: 1.2,
              colors: [
                AppColors.primaryDark,
                AppColors.primaryMedium,
                AppColors.primaryDark,
                AppColors.primaryMedium.withOpacity(0.6),
                AppColors.primaryDark,
              ],
              stops: const [0.0, 0.35, 0.6, 0.8, 1.0],
            ),
          ),
        );
      },
    );
  }
}
