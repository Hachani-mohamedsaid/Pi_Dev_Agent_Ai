import 'package:flutter/material.dart';

/// Displays success probability as a large percentage with optional label.
class ProbabilityIndicator extends StatelessWidget {
  final int successProbability;
  final String? label;

  const ProbabilityIndicator({
    super.key,
    required this.successProbability,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = successProbability >= 70
        ? Colors.green
        : successProbability >= 40
            ? Colors.orange
            : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$successProbability%',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ) ?? TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (label != null && label!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
