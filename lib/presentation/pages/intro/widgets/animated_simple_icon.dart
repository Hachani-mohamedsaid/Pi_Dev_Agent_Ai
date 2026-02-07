import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Icône simple avec animation en boucle (pulse scale + légère opacité).
/// Utilisé pour l'intro au lieu d'images ou Lottie complexes.
class AnimatedSimpleIcon extends StatefulWidget {
  const AnimatedSimpleIcon({
    super.key,
    required this.icon,
    this.size = 120,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  State<AnimatedSimpleIcon> createState() => _AnimatedSimpleIconState();
}

class _AnimatedSimpleIconState extends State<AnimatedSimpleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.cyan400.withOpacity(0.95);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
