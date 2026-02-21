import 'package:flutter/material.dart';

/// Colored badge for risk level (Low / Medium / High).
class RiskBadge extends StatelessWidget {
  final String riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  Color get _color {
    final lower = riskLevel.toLowerCase();
    if (lower.contains('low')) return Colors.green;
    if (lower.contains('medium') || lower.contains('moderate')) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.6)),
      ),
      child: Text(
        riskLevel,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _color,
          fontSize: 14,
        ),
      ),
    );
  }
}
