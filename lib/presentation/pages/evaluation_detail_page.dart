import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/guest_interview_link.dart';
import '../../data/models/evaluation.dart';
import '../../data/services/interview_invite_email_api_service.dart';

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
                      const SizedBox(height: 20),
                      _SendGuestInterviewEmailButton(evaluation: evaluation),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final link = guestInterviewLinkString(evaluation);
                            await Clipboard.setData(ClipboardData(text: link));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Lien candidat copié dans le presse-papiers.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor:
                                    AppColors.primaryDarker.withValues(alpha: 0.95),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.link, size: 20),
                          label: const Text('Copier le lien d’entretien (candidat)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan400,
                            side: BorderSide(
                              color: AppColors.cyan400.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push(
                            '/candidate-interview',
                            extra: evaluation,
                          ),
                          icon: const Icon(LucideIcons.messageCircle, size: 20),
                          label: const Text('Entretien assisté (aperçu recruteur)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyan500,
                            foregroundColor: const Color(0xFF0a1628),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
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

/// Tente d’abord `POST /interviews/send-invite-email` (envoi serveur), puis repli `mailto:`.
class _SendGuestInterviewEmailButton extends StatefulWidget {
  const _SendGuestInterviewEmailButton({required this.evaluation});

  final Evaluation evaluation;

  @override
  State<_SendGuestInterviewEmailButton> createState() =>
      _SendGuestInterviewEmailButtonState();
}

class _SendGuestInterviewEmailButtonState
    extends State<_SendGuestInterviewEmailButton> {
  final _api = InterviewInviteEmailApiService();
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final res = await _api.sendGuestInterviewInvite(widget.evaluation);
    if (!mounted) return;
    setState(() => _sending = false);
    final link = guestInterviewLinkString(widget.evaluation);
    final localhost =
        link.contains('localhost') || link.contains('127.0.0.1');

    void openMailto() {
      final mailto = guestInterviewMailtoUri(widget.evaluation);
      if (mailto != null) {
        launchUrl(mailto, mode: LaunchMode.externalApplication);
      }
    }

    switch (res.kind) {
      case InviteEmailSendKind.success:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              localhost
                  ? 'E-mail envoyé. Le lien contient encore localhost : le candidat ne pourra pas l’ouvrir depuis chez lui. '
                      'Passez APP_PUBLIC_ORIGIN (build web) ou un domaine public.'
                  : 'E-mail envoyé au candidat avec le lien d’entretien.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryDarker.withValues(alpha: 0.95),
          ),
        );
        break;
      case InviteEmailSendKind.notImplemented:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              res.message ??
                  'Le backend n’expose pas encore POST /interviews/send-invite-email — ouverture de Mail en secours possible.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Ouvrir Mail',
              textColor: AppColors.cyan400,
              onPressed: openMailto,
            ),
            backgroundColor: AppColors.primaryDarker.withValues(alpha: 0.95),
          ),
        );
        break;
      default:
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Envoi impossible.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.statusRejected.withValues(alpha: 0.95),
            action: SnackBarAction(
              label: 'Ouvrir Mail',
              textColor: Colors.white70,
              onPressed: openMailto,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _sending ? null : _send,
        icon: _sending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0a1628),
                ),
              )
            : const Icon(LucideIcons.mail, size: 20),
        label: Text(
          _sending ? 'Envoi en cours…' : 'Envoyer le lien par e-mail au candidat',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan500,
          foregroundColor: const Color(0xFF0a1628),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
