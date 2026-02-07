import 'package:flutter/material.dart';

/// Button with press animation (scale to 0.96) and ripple/glow feedback.
class ScalePressButton extends StatefulWidget {
  const ScalePressButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.minWidth,
    this.minHeight,
    this.border,
    this.boxShadow,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? minHeight;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  @override
  State<ScalePressButton> createState() => _ScalePressButtonState();
}

class _ScalePressButtonState extends State<ScalePressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          constraints: BoxConstraints(
            minWidth: widget.minWidth ?? 200,
            minHeight: widget.minHeight ?? 52,
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            border: widget.border,
            boxShadow: widget.boxShadow ??
                (widget.backgroundColor != null && widget.backgroundColor != Colors.transparent
                    ? [
                        BoxShadow(
                          color: (widget.backgroundColor ?? Colors.cyan)
                              .withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.foregroundColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
