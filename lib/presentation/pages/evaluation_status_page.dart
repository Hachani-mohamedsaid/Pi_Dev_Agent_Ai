import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/evaluation_status.dart';
import '../../data/services/ats_api.dart';

/// Page de suivi du statut d'évaluation d'une candidature.
///
/// Si [evaluationId] est vide, tente de charger le dernier ID depuis
/// SharedPreferences. Si aucun ID n'est disponible, affiche un
/// message « Aucune candidature récente ».
class EvaluationStatusPage extends StatefulWidget {
  final String evaluationId;

  const EvaluationStatusPage({super.key, required this.evaluationId});

  @override
  State<EvaluationStatusPage> createState() => _EvaluationStatusPageState();
}

class _EvaluationStatusPageState extends State<EvaluationStatusPage> {
  final _api = AtsApi();
  Timer? _pollTimer;

  String _evaluationId = '';
  EvaluationStatus? _status;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveEvaluationId();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolveEvaluationId() async {
    var id = widget.evaluationId;
    if (id.isEmpty) {
      id = await AtsApi.loadEvaluationId() ?? '';
    }
    if (!mounted) return;
    setState(() => _evaluationId = id);
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.getEvaluationStatus(_evaluationId);
      if (!mounted) return;
      setState(() {
        _status = result;
        _loading = false;
      });

      if (result.isPending) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
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

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      _fetchStatus();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────

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
              'Suivi Évaluation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ),
          if (_evaluationId.isNotEmpty)
            IconButton(
              onPressed: _fetchStatus,
              icon: const Icon(LucideIcons.refreshCw, color: AppColors.cyan400),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Aucun evaluationId
    if (_evaluationId.isEmpty && !_loading) {
      return _buildEmpty();
    }

    // Chargement initial
    if (_loading && _status == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.cyan400),
            SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(color: AppColors.textCyan200, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // Erreur
    if (_error != null) {
      return _buildError();
    }

    final status = _status!;

    // Pending (en attente)
    if (status.isPending) {
      return _buildPending();
    }

    // Processed (résultat disponible)
    return _buildProcessed(status);
  }

  // ── Pas de candidature ───────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 64, color: AppColors.cyan400.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            const Text(
              'Aucune candidature récente',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soumettez une candidature via le formulaire pour suivre son évaluation ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textCyan200, fontSize: 14),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/create-job'),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Retour'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.cyan500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Erreur ───────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 56, color: AppColors.statusRejected),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchStatus,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.cyan500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pending ──────────────────────────────────────────────────────

  Widget _buildPending() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.statusPending,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Évaluation en cours...',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Actualisation automatique toutes les 3 secondes',
              style: TextStyle(color: AppColors.textCyan200.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Processed ────────────────────────────────────────────────────

  Widget _buildProcessed(EvaluationStatus status) {
    final isShortlist = status.decision?.toLowerCase() == 'shortlist';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Score card
          Card(
            color: const Color(0xFF142E42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Score',
                    style: TextStyle(color: AppColors.textCyan200, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status.score != null ? '${status.score}' : '—',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(status.score),
                    ),
                  ),
                  if (status.score != null)
                    Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textCyan200.withValues(alpha: 0.6),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _decisionBadge(status.decision, isShortlist),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Strengths
          if (status.strengths != null && status.strengths!.isNotEmpty)
            _expandableSection(
              title: 'Points forts',
              icon: LucideIcons.thumbsUp,
              color: AppColors.statusAccepted,
              content: status.strengths!,
            ),

          // Weaknesses
          if (status.weaknesses != null && status.weaknesses!.isNotEmpty)
            _expandableSection(
              title: 'Points faibles',
              icon: LucideIcons.thumbsDown,
              color: AppColors.statusRejected,
              content: status.weaknesses!,
            ),
        ],
      ),
    );
  }

  Widget _decisionBadge(String? decision, bool isShortlist) {
    if (decision == null || decision.isEmpty) return const SizedBox.shrink();

    final color = isShortlist ? AppColors.statusAccepted : AppColors.statusRejected;
    final icon = isShortlist ? LucideIcons.checkCircle : LucideIcons.xCircle;
    final label = isShortlist ? 'Shortlist' : decision[0].toUpperCase() + decision.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _expandableSection({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: const Color(0xFF142E42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: color, size: 20),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          iconColor: AppColors.cyan400,
          collapsedIconColor: AppColors.textCyan200,
          children: [
            Text(
              content,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ],
        ),
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
