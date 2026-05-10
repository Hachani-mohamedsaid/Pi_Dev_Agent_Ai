import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/evaluation.dart';

/// Aperçu **statique** de l’entretien assisté : aucun appel réseau, aucune clé API.
/// Utile tant que `POST /interviews/start` n’est pas disponible sur le backend.
class CandidateInterviewStaticPage extends StatelessWidget {
  const CandidateInterviewStaticPage({super.key, this.evaluation});

  final Evaluation? evaluation;

  String get _candidateLabel {
    final n = evaluation?.candidateName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Candidat';
  }

  String get _jobLabel {
    final j = evaluation?.jobTitle?.trim();
    if (j != null && j.isNotEmpty) return j;
    return 'Poste à pourvoir';
  }

  List<_StaticLine> get _script {
    return [
      _StaticLine(
        isRecruiter: false,
        text:
            'Bonjour, $_candidateLabel. Je suis l’assistant d’entretien (aperçu statique).\n\n'
            'Dans la version connectée au serveur, cette conversation sera générée par l’IA '
            '(Gemini) à partir du poste « $_jobLabel » et restera confidentielle.',
      ),
      _StaticLine(
        isRecruiter: true,
        text:
            'Pourriez-vous vous présenter brièvement et expliquer ce qui vous motive pour ce poste ?',
      ),
      _StaticLine(
        isRecruiter: false,
        text:
            'Exemple de réponse (démo) : « Je suis développeur full-stack depuis cinq ans, '
            'avec une forte appétence pour les produits orientés utilisateur… »\n\n'
            '— Ici, le texte serait produit en temps réel par le modèle, pas prédéfini.',
      ),
      _StaticLine(
        isRecruiter: true,
        text:
            'Comment aborderiez-vous un retard important sur une livraison, avec l’équipe et le client ?',
      ),
      _StaticLine(
        isRecruiter: false,
        text:
            'Exemple (démo) : transparence sur les causes, plan de rattrapage chiffré, '
            'et point régulier avec les parties prenantes.',
      ),
    ];
  }

  void _showStaticSummary(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142E42),
        title: const Text(
          'Synthèse (démo)',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Ceci est une synthèse factice pour l’aperçu.\n\n'
            'Avec le backend actif, une synthèse automatique pourra résumer les points forts, '
            'les risques et une recommandation (à valider par un humain).\n\n'
            'Candidat : $_candidateLabel\n'
            'Poste : $_jobLabel',
            style: const TextStyle(
              color: AppColors.textCyan200,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = _script;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f2940),
              Color(0xFF1a3a52),
              Color(0xFF0f2940),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        LucideIcons.arrowLeft,
                        color: AppColors.textWhite,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _candidateLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Entretien assisté (aperçu statique)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textCyan200.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showStaticSummary(context),
                      child: const Text('Terminer'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cyan400.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyan400.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: AppColors.cyan400,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mode démonstration : aucun appel au serveur, aucune donnée envoyée à un LLM. '
                            'Branchez l’API Nest `/interviews` pour activer l’entretien réel.',
                            style: TextStyle(
                              color: AppColors.textCyan200.withValues(alpha: 0.95),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (evaluation?.jobTitle != null &&
                  evaluation!.jobTitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      evaluation!.jobTitle!,
                      style: TextStyle(
                        color: AppColors.textCyan200.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: lines.length,
                  itemBuilder: (context, i) => _StaticBubble(line: lines[i]),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.textCyan200.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Text(
                  'Saisie désactivée en mode statique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.55),
                    fontSize: 13,
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

class _StaticLine {
  _StaticLine({required this.isRecruiter, required this.text});
  final bool isRecruiter;
  final String text;
}

class _StaticBubble extends StatelessWidget {
  const _StaticBubble({required this.line});

  final _StaticLine line;

  @override
  Widget build(BuildContext context) {
    final recruiter = line.isRecruiter;
    return Align(
      alignment: recruiter ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: recruiter
              ? AppColors.cyan500.withValues(alpha: 0.25)
              : AppColors.primaryDarker.withValues(alpha: 0.95),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(recruiter ? 16 : 4),
            bottomRight: Radius.circular(recruiter ? 4 : 16),
          ),
          border: Border.all(
            color: recruiter
                ? AppColors.cyan400.withValues(alpha: 0.35)
                : AppColors.textCyan200.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          line.text,
          style: TextStyle(
            color: recruiter ? AppColors.textWhite : AppColors.textCyan200,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
