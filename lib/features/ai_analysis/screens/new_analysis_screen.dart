import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/analysis_provider.dart';
import 'analysis_history_screen.dart';

/// Screen to enter a startup idea and trigger AI analysis.
class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final provider = context.read<AnalysisProvider>();
    await provider.analyze(_controller.text);
    if (!mounted) return;
    if (provider.status == AnalysisStatus.success && provider.result != null) {
      context.push('/ai-analysis-result', extra: provider.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Project Analyzer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history),
            onPressed: () => context.push('/ai-analysis-history'),
            tooltip: 'History',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Describe your startup idea',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'e.g. A coffee shop in the city center with a budget of 5000 DT...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              Consumer<AnalysisProvider>(
                builder: (context, provider, _) {
                  final loading = provider.status == AnalysisStatus.loading;
                  if (provider.status == AnalysisStatus.error) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        provider.errorMessage,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              FilledButton.icon(
                onPressed: () async {
                  final provider = context.read<AnalysisProvider>();
                  if (provider.status == AnalysisStatus.loading) return;
                  await _analyze();
                },
                icon: Consumer<AnalysisProvider>(
                  builder: (context, provider, _) {
                    if (provider.status == AnalysisStatus.loading) {
                      return SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      );
                    }
                    return const Icon(LucideIcons.sparkles, size: 20);
                  },
                ),
                label: Consumer<AnalysisProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      provider.status == AnalysisStatus.loading
                          ? 'Analyzing...'
                          : 'Analyze',
                    );
                  },
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
