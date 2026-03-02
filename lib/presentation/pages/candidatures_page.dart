import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/evaluation.dart';
import '../../data/services/ats_api.dart';

/// Liste des candidatures (vue recruteur) avec filtres et pull-to-refresh.
class CandidaturesPage extends StatefulWidget {
  const CandidaturesPage({super.key});

  @override
  State<CandidaturesPage> createState() => _CandidaturesPageState();
}

enum _Filter { all, shortlist, reject, pending }

class _CandidaturesPageState extends State<CandidaturesPage> {
  final _api = AtsApi();

  List<Evaluation> _all = [];
  bool _loading = true;
  String? _error;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final evaluations = await _api.getEvaluations();
      if (!mounted) return;
      setState(() {
        _all = evaluations;
        _loading = false;
      });
    } on AtsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'Timeout — réessayez';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<Evaluation> get _filtered {
    switch (_filter) {
      case _Filter.shortlist:
        return _all.where((e) => e.isShortlist).toList();
      case _Filter.reject:
        return _all.where((e) => e.isRejected).toList();
      case _Filter.pending:
        return _all.where((e) => e.isPending).toList();
      case _Filter.all:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildFilters(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/create-job'),
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textWhite),
          ),
          const Expanded(
            child: Text(
              'Candidatures',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _load,
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.cyan400),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _Filter.values.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(_filterLabel(f)),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textCyan200,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              selectedColor: _filterColor(f),
              backgroundColor: const Color(0xFF142E42),
              side: BorderSide(
                color: selected
                    ? _filterColor(f)
                    : AppColors.cyan500.withValues(alpha: 0.2),
              ),
              onSelected: (_) => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(_Filter f) {
    switch (f) {
      case _Filter.all:
        return 'Tous (${_all.length})';
      case _Filter.shortlist:
        return 'Shortlist (${_all.where((e) => e.isShortlist).length})';
      case _Filter.reject:
        return 'Rejetés (${_all.where((e) => e.isRejected).length})';
      case _Filter.pending:
        return 'En attente (${_all.where((e) => e.isPending).length})';
    }
  }

  Color _filterColor(_Filter f) {
    switch (f) {
      case _Filter.all:
        return AppColors.cyan500;
      case _Filter.shortlist:
        return AppColors.statusAccepted;
      case _Filter.reject:
        return AppColors.statusRejected;
      case _Filter.pending:
        return AppColors.statusPending;
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan400),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  size: 56, color: AppColors.statusRejected),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Réessayer'),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.cyan500),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filtered;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox,
                size: 56,
                color: AppColors.cyan400.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Aucune candidature pour le moment',
              style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.cyan400,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        itemBuilder: (_, i) => _EvaluationCard(
          evaluation: items[i],
          onTap: () => context.push(
            '/evaluation-detail',
            extra: items[i],
          ),
        ),
      ),
    );
  }
}

// ── Card widget ────────────────────────────────────────────────────

class _EvaluationCard extends StatelessWidget {
  final Evaluation evaluation;
  final VoidCallback onTap;

  const _EvaluationCard({required this.evaluation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF142E42),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.cyan500.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: name + badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        evaluation.candidateName ?? 'Candidat inconnu',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _badge(),
                  ],
                ),

                if (evaluation.candidateEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    evaluation.candidateEmail!,
                    style: TextStyle(
                        color: AppColors.textCyan200.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                ],

                const SizedBox(height: 8),

                // Job info row
                Row(
                  children: [
                    const Icon(LucideIcons.briefcase,
                        size: 14, color: AppColors.cyan400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        evaluation.jobTitle ?? evaluation.jobId ?? '—',
                        style: const TextStyle(
                            color: AppColors.textCyan200, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (evaluation.score != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _scoreColor(evaluation.score)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${evaluation.score}/100',
                          style: TextStyle(
                            color: _scoreColor(evaluation.score),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Date
                if (evaluation.displayDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    evaluation.displayDate,
                    style: TextStyle(
                        color: AppColors.textCyan200.withValues(alpha: 0.5),
                        fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge() {
    Color color;
    String label;
    if (evaluation.isShortlist) {
      color = AppColors.statusAccepted;
      label = 'Shortlist';
    } else if (evaluation.isRejected) {
      color = AppColors.statusRejected;
      label = 'Rejeté';
    } else {
      color = AppColors.statusPending;
      label = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _scoreColor(int? score) {
    if (score == null) return AppColors.textCyan200;
    if (score >= 70) return AppColors.statusAccepted;
    if (score >= 40) return AppColors.statusPending;
    return AppColors.statusRejected;
  }
}
