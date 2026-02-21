import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Risk badge in app style (cyan/green/amber/red).
class AdvisorRiskBadge extends StatelessWidget {
  final String riskLevel;

  const AdvisorRiskBadge({super.key, required this.riskLevel});

  Color get _color {
    final lower = riskLevel.toLowerCase();
    if (lower.contains('low')) return const Color(0xFF10B981);
    if (lower.contains('medium') || lower.contains('moderate')) return const Color(0xFFF59E0B);
    return AppColors.statusRejected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          fontSize: 13,
        ),
      ),
    );
  }
}
