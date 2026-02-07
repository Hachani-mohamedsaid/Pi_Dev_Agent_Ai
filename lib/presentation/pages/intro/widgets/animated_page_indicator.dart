import 'package:flutter/material.dart';

/// Animated page indicator dots. Active dot expands smoothly.
class AnimatedPageIndicator extends StatelessWidget {
  const AnimatedPageIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    this.activeColor,
    this.inactiveColor,
    this.size = 8,
    this.activeSize = 12,
  });

  final int currentIndex;
  final int itemCount;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  final double activeSize;

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? const Color(0xFF22D3EE);
    final inactive = inactiveColor ?? const Color(0xFF1E4A66);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: isActive ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final w = size + (activeSize - size) * value;
            final h = size;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: Color.lerp(inactive, active, value)!,
                borderRadius: BorderRadius.circular(size / 2),
              ),
            );
          },
        );
      }),
    );
  }
}
