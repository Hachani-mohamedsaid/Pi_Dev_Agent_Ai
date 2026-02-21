import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/analysis_model.dart';
import '../widgets/probability_indicator.dart';
import '../widgets/risk_badge.dart';
import '../widgets/analysis_card.dart';

/// Displays the result of an AI business feasibility analysis.
class AnalysisResultScreen extends StatelessWidget {
  final AnalysisModel analysis;

  const AnalysisResultScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnalysisCard(
                title: 'Project Summary',
                child: Text(
                  analysis.projectSummary,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ProbabilityIndicator(
                  successProbability: analysis.successProbability,
                  label: 'Success probability',
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Failure: ${analysis.failureProbability}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnalysisCard(
                title: 'Viability',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      analysis.viability,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnalysisCard(
                title: 'Risk Level',
                child: RiskBadge(riskLevel: analysis.riskLevel),
              ),
              const SizedBox(height: 16),
              AnalysisCard(
                title: 'Advice',
                child: Text(
                  analysis.advice,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
