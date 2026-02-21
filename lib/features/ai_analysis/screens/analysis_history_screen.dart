import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/analysis_model.dart';
import '../providers/analysis_provider.dart';
import '../widgets/risk_badge.dart';
import 'analysis_result_screen.dart';

/// Lists previously saved analyses; tap to view result.
class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<AnalysisModel>>(
        future: context.read<AnalysisProvider>().getAnalyses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No analyses yet.\nRun an analysis from the AI Project Analyzer.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final summary = item.projectSummary;
              final short = summary.length > 80 ? '${summary.substring(0, 80)}...' : summary;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(short),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Text('${item.successProbability}% success'),
                        const SizedBox(width: 12),
                        RiskBadge(riskLevel: item.riskLevel),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  onTap: () => context.push(
                    '/ai-analysis-result',
                    extra: item,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
