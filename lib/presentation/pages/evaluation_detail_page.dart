import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/evaluation.dart';

/// Détail d'une évaluation candidat — score, décision, forces/faiblesses, infos.
class EvaluationDetailPage extends StatelessWidget {
  final Evaluation evaluation;

  const EvaluationDetailPage({super.key, required this.evaluation});

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
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _scoreCard(),
                      const SizedBox(height: 16),
                      if (_hasText(evaluation.strengths))
                        _expandableSection(
                          title: 'Points forts',
                          icon: LucideIcons.thumbsUp,
                          color: AppColors.statusAccepted,
                          content: evaluation.strengths!,
                        ),
                      if (_hasText(evaluation.weaknesses))
                        _expandableSection(
                          title: 'Points faibles',
                          icon: LucideIcons.thumbsDown,
                          color: AppColors.statusRejected,
                          content: evaluation.weaknesses!,
                        ),
                      _infoCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textWhite),
          ),
          Expanded(
            child: Text(
              evaluation.candidateName ?? 'Détail évaluation',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Score + Décision ─────────────────────────────────────────────

  Widget _scoreCard() {
    final isShortlist = evaluation.isShortlist;

    return Card(
      color: const Color(0xFF142E42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Column(
          children: [
            const Text('Score',
                style: TextStyle(color: AppColors.textCyan200, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              evaluation.score != null ? '${evaluation.score}' : '—',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: _scoreColor(evaluation.score),
              ),
            ),
            if (evaluation.score != null)
              Text('/ 100',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textCyan200.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            if (evaluation.decision != null &&
                evaluation.decision!.isNotEmpty)
              _decisionBadge(evaluation.decisionLabel, isShortlist),
          ],
        ),
      ),
    );
  }

  Widget _decisionBadge(String label, bool isShortlist) {
    final color =
        isShortlist ? AppColors.statusAccepted : AppColors.statusRejected;
    final icon = isShortlist ? LucideIcons.checkCircle : LucideIcons.xCircle;

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
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Expandable Strengths / Weaknesses ───────────────────────────

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
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          iconColor: AppColors.cyan400,
          collapsedIconColor: AppColors.textCyan200,
          children: [
            Text(content,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ── Info Card (candidat + job + meta) ────────────────────────────

  Widget _infoCard() {
    return Card(
      color: const Color(0xFF142E42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations',
                style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const Divider(color: Colors.white12),
            if (_hasText(evaluation.candidateEmail))
              _infoRow(LucideIcons.mail, 'Email', evaluation.candidateEmail!),
            if (_hasText(evaluation.phone))
              _infoRow(LucideIcons.phone, 'Téléphone', evaluation.phone!),
            if (_hasText(evaluation.linkedin))
              _linkRow(
                  LucideIcons.linkedin, 'LinkedIn', evaluation.linkedin!),
            if (_hasText(evaluation.cvUrl))
              _linkRow(LucideIcons.fileText, 'CV', evaluation.cvUrl!),
            const Divider(color: Colors.white12),
            if (_hasText(evaluation.jobTitle))
              _infoRow(
                  LucideIcons.briefcase, 'Poste', evaluation.jobTitle!),
            if (_hasText(evaluation.jobId))
              _infoRow(LucideIcons.hash, 'Job ID', evaluation.jobId!),
            if (_hasText(evaluation.evaluationId))
              _infoRow(
                  LucideIcons.tag, 'Eval ID', evaluation.evaluationId!),
            if (evaluation.displayDate.isNotEmpty)
              _infoRow(
                  LucideIcons.clock, 'Date', evaluation.displayDate),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.cyan400),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(
                  color: AppColors.textCyan200,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(IconData icon, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.cyan400),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(
                  color: AppColors.textCyan200,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                url,
                style: const TextStyle(
                    color: AppColors.cyan400,
                    decoration: TextDecoration.underline,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasText(String? v) => v != null && v.isNotEmpty;

  Color _scoreColor(int? score) {
    if (score == null) return AppColors.textCyan200;
    if (score >= 70) return AppColors.statusAccepted;
    if (score >= 40) return AppColors.statusPending;
    return AppColors.statusRejected;
  }
}
