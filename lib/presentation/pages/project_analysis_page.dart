import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/work_proposal_model.dart';
import '../../data/services/openai_analysis_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/app_colors.dart';

class ProjectAnalysisPage extends StatefulWidget {
  final WorkProposal proposal;

  const ProjectAnalysisPage({
    super.key,
    required this.proposal,
  });

  @override
  State<ProjectAnalysisPage> createState() => _ProjectAnalysisPageState();
}

class _ProjectAnalysisPageState extends State<ProjectAnalysisPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _sectionControllers = [];
  final OpenAIAnalysisService _analysisService = OpenAIAnalysisService();
  ProjectAnalysis? _analysis;
  bool _isLoadingAnalysis = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Controllers pour chaque section
    for (int i = 0; i < 6; i++) {
      _sectionControllers.add(
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 400 + (i * 100)),
        ),
      );
    }

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        for (var controller in _sectionControllers) {
          controller.forward();
        }
      });
    });
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoadingAnalysis = true;
    });
    try {
      final analysis = await _analysisService.analyzeProject(widget.proposal);
      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoadingAnalysis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAnalysis = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatBudget(double budget) {
    if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}k €';
    }
    return '${budget.toStringAsFixed(0)} €';
  }

  Color _getComplexityColor(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'simple':
        return const Color(0xFF10B981);
      case 'moyen':
        return const Color(0xFFF59E0B);
      case 'complexe':
        return const Color(0xFFEF4444);
      default:
        return AppColors.cyan400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  _AnalysisHeader(
                    proposal: widget.proposal,
                    isMobile: isMobile,
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getResponsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        ),
                        vertical: 16,
                      ),
                      children: [
                        // Section 1: Détails du projet
                        _AnimatedSection(
                          index: 0,
                          controller: _sectionControllers[0],
                          child: _ProjectDetailsSection(
                            proposal: widget.proposal,
                            formatBudget: _formatBudget,
                            getComplexityColor: _getComplexityColor,
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                        // Section 2: Outils utilisés
                        _AnimatedSection(
                          index: 1,
                          controller: _sectionControllers[1],
                          child: _isLoadingAnalysis
                              ? _LoadingSection(message: 'Analyse des outils en cours...')
                              : _ToolsSection(
                                  proposal: widget.proposal,
                                  analysis: _analysis,
                                  isMobile: isMobile,
                                ),
                        ),
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                        // Section 3: Proposition technique
                        _AnimatedSection(
                          index: 2,
                          controller: _sectionControllers[2],
                          child: _isLoadingAnalysis
                              ? _LoadingSection(message: 'Analyse technique en cours...')
                              : _TechnicalProposalSection(
                                  proposal: widget.proposal,
                                  analysis: _analysis,
                                  isMobile: isMobile,
                                ),
                        ),
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                        // Section 4: Comment travailler ce projet
                        _AnimatedSection(
                          index: 3,
                          controller: _sectionControllers[3],
                          child: _isLoadingAnalysis
                              ? _LoadingSection(message: 'Analyse méthodologie en cours...')
                              : _HowToWorkSection(
                                  proposal: widget.proposal,
                                  analysis: _analysis,
                                  isMobile: isMobile,
                                ),
                        ),
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                        // Section 5: Étapes de développement
                        _AnimatedSection(
                          index: 4,
                          controller: _sectionControllers[4],
                          child: _isLoadingAnalysis
                              ? _LoadingSection(message: 'Analyse des étapes en cours...')
                              : _DevelopmentStepsSection(
                                  proposal: widget.proposal,
                                  analysis: _analysis,
                                  isMobile: isMobile,
                                ),
                        ),
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                        // Section 6: Recommandations
                        _AnimatedSection(
                          index: 5,
                          controller: _sectionControllers[5],
                          child: _isLoadingAnalysis
                              ? _LoadingSection(message: 'Analyse recommandations en cours...')
                              : _RecommendationsSection(
                                  proposal: widget.proposal,
                                  analysis: _analysis,
                                  isMobile: isMobile,
                                ),
                        ),
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Header avec bouton retour
class _AnalysisHeader extends StatelessWidget {
  final WorkProposal proposal;
  final bool isMobile;

  const _AnalysisHeader({
    required this.proposal,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        ),
        vertical: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderCyan,
                ),
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                color: AppColors.textWhite,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
              ),
            ),
          ),
          SizedBox(
            width: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse du projet',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveValue(
                    context,
                    mobile: 4.0,
                    tablet: 6.0,
                    desktop: 8.0,
                  ),
                ),
                Text(
                  proposal.projectName,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 15.0,
                      desktop: 16.0,
                    ),
                    color: AppColors.textCyan200.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Section animée
class _AnimatedSection extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;

  const _AnimatedSection({
    required this.index,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

// Section: Détails du projet
class _ProjectDetailsSection extends StatelessWidget {
  final WorkProposal proposal;
  final String Function(double) formatBudget;
  final Color Function(String) getComplexityColor;
  final bool isMobile;

  const _ProjectDetailsSection({
    required this.proposal,
    required this.formatBudget,
    required this.getComplexityColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Détails du projet',
      icon: LucideIcons.folderOpen,
      iconColor: AppColors.cyan400,
      isMobile: isMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            icon: LucideIcons.briefcase,
            label: 'Type de projet',
            value: proposal.typeProjet,
            iconColor: AppColors.cyan400,
            isMobile: isMobile,
          ),
          SizedBox(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
          ),
          _DetailRow(
            icon: LucideIcons.building,
            label: 'Secteur',
            value: proposal.secteur,
            iconColor: AppColors.cyan400,
            isMobile: isMobile,
          ),
          SizedBox(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
          ),
          _DetailRow(
            icon: LucideIcons.monitor,
            label: 'Plateforme',
            value: proposal.platforme,
            iconColor: AppColors.cyan400,
            isMobile: isMobile,
          ),
          SizedBox(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
          ),
          _DetailRow(
            icon: LucideIcons.euro,
            label: 'Budget estimé',
            value: formatBudget(proposal.budgetEstime),
            iconColor: const Color(0xFF10B981),
            isMobile: isMobile,
          ),
          SizedBox(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
          ),
          _DetailRow(
            icon: LucideIcons.calendar,
            label: 'Délai estimé',
            value: proposal.deadlineEstime,
            iconColor: AppColors.cyan400,
            isMobile: isMobile,
          ),
          SizedBox(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
          ),
          Row(
            children: [
              Icon(
                LucideIcons.activity,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
                color: getComplexityColor(proposal.niveauComplexite),
              ),
              SizedBox(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau de complexité',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                        color: AppColors.textCyan200.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 6.0,
                        desktop: 8.0,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                        vertical: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: getComplexityColor(proposal.niveauComplexite)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: getComplexityColor(proposal.niveauComplexite)
                              .withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        proposal.niveauComplexite,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 13.0,
                            tablet: 14.0,
                            desktop: 15.0,
                          ),
                          fontWeight: FontWeight.w600,
                          color: getComplexityColor(proposal.niveauComplexite),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Section: Outils utilisés
class _ToolsSection extends StatelessWidget {
  final WorkProposal proposal;
  final ProjectAnalysis? analysis;
  final bool isMobile;

  const _ToolsSection({
    required this.proposal,
    this.analysis,
    required this.isMobile,
  });

  List<String> _getToolsForProject() {
    if (analysis != null && analysis!.tools.isNotEmpty) {
      return analysis!.tools;
    }
    final tools = <String>[];
    final platforme = proposal.platforme.toLowerCase();
    final typeProjet = proposal.typeProjet.toLowerCase();

    // Outils de développement
    if (platforme.contains('mobile') || platforme.contains('ios') || platforme.contains('android')) {
      tools.addAll(['Flutter', 'Dart', 'Android Studio', 'Xcode']);
    } else if (platforme.contains('web')) {
      tools.addAll(['React', 'TypeScript', 'Node.js', 'Next.js']);
    }

    // Outils de design
    if (typeProjet.contains('design') || typeProjet.contains('ui') || typeProjet.contains('ux')) {
      tools.addAll(['Figma', 'Adobe XD', 'Sketch']);
    }

    // Outils de versioning et CI/CD
    tools.addAll(['Git', 'GitHub', 'GitLab']);

    // Outils de gestion de projet
    tools.addAll(['Jira', 'Trello', 'Notion']);

    // Outils de test
    if (proposal.niveauComplexite.toLowerCase() == 'complexe') {
      tools.addAll(['Jest', 'Cypress', 'Postman']);
    }

    // Outils de déploiement
    if (platforme.contains('web')) {
      tools.addAll(['Vercel', 'Netlify', 'AWS']);
    } else if (platforme.contains('mobile')) {
      tools.addAll(['Firebase', 'App Store Connect', 'Google Play Console']);
    }

    return tools;
  }

  @override
  Widget build(BuildContext context) {
    final tools = _getToolsForProject();

    return _SectionCard(
      title: 'Outils utilisés',
      icon: LucideIcons.wrench,
      iconColor: const Color(0xFF8B5CF6),
      isMobile: isMobile,
      child: Wrap(
        spacing: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        ),
        runSpacing: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        ),
        children: tools.map((tool) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
              vertical: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                  color: const Color(0xFF8B5CF6),
                ),
                SizedBox(
                  width: Responsive.getResponsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
                Text(
                  tool,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 15.0,
                      desktop: 16.0,
                    ),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Section: Proposition technique
class _TechnicalProposalSection extends StatelessWidget {
  final WorkProposal proposal;
  final ProjectAnalysis? analysis;
  final bool isMobile;

  const _TechnicalProposalSection({
    required this.proposal,
    this.analysis,
    required this.isMobile,
  });

  List<_TechnicalAspect> _getTechnicalAspects() {
    if (analysis != null) {
      final tp = analysis!.technicalProposal;
      return [
        _TechnicalAspect(
          icon: LucideIcons.layers,
          title: 'Architecture',
          description: tp.architecture,
          color: AppColors.cyan400,
        ),
        _TechnicalAspect(
          icon: LucideIcons.code,
          title: 'Stack',
          description: tp.stack,
          color: const Color(0xFF8B5CF6),
        ),
        _TechnicalAspect(
          icon: LucideIcons.shield,
          title: 'Sécurité',
          description: tp.security,
          color: const Color(0xFF10B981),
        ),
        _TechnicalAspect(
          icon: LucideIcons.zap,
          title: 'Performance',
          description: tp.performance,
          color: const Color(0xFFF59E0B),
        ),
        _TechnicalAspect(
          icon: LucideIcons.checkCircle,
          title: 'Tests',
          description: tp.tests,
          color: const Color(0xFF06B6D4),
        ),
        _TechnicalAspect(
          icon: LucideIcons.rocket,
          title: 'Déploiement',
          description: tp.deployment,
          color: const Color(0xFFEF4444),
        ),
        _TechnicalAspect(
          icon: LucideIcons.barChart,
          title: 'Monitoring',
          description: tp.monitoring,
          color: const Color(0xFFEC4899),
        ),
      ];
    }
    final platforme = proposal.platforme.toLowerCase();
    final complexite = proposal.niveauComplexite.toLowerCase();
    final aspects = <_TechnicalAspect>[];

    // Architecture
    if (platforme.contains('mobile')) {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.layers,
        title: 'Architecture',
        description:
            'Utilisation de Flutter pour un développement cross-platform permettant de cibler iOS et Android avec un seul codebase. Architecture modulaire avec séparation des couches (présentation, logique métier, données).',
        color: AppColors.cyan400,
      ));
    } else if (platforme.contains('web')) {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.layers,
        title: 'Architecture',
        description:
            'Application web moderne avec React/Next.js pour une expérience utilisateur optimale. Architecture microservices pour une scalabilité et une maintenabilité accrues.',
        color: AppColors.cyan400,
      ));
    }

    // Stack technique
    if (platforme.contains('mobile')) {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.code,
        title: 'Stack technique',
        description:
            'Flutter/Dart, Firebase pour l\'authentification et la base de données, Provider/Riverpod pour la gestion d\'état.',
        color: const Color(0xFF8B5CF6),
      ));
    } else if (platforme.contains('web')) {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.code,
        title: 'Stack technique',
        description:
            'React/TypeScript, Node.js pour le backend, PostgreSQL pour la base de données, Redis pour le cache.',
        color: const Color(0xFF8B5CF6),
      ));
    }

    // Sécurité
    aspects.add(_TechnicalAspect(
      icon: LucideIcons.shield,
      title: 'Sécurité',
      description:
          'Implémentation de bonnes pratiques de sécurité (HTTPS, authentification JWT, validation des données, protection CSRF).',
      color: const Color(0xFF10B981),
    ));

    // Performance
    if (complexite == 'complexe') {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.zap,
        title: 'Performance',
        description:
            'Optimisation des performances avec lazy loading, code splitting, mise en cache intelligente, et CDN pour les assets statiques.',
        color: const Color(0xFFF59E0B),
      ));
    }

    // Tests
    aspects.add(_TechnicalAspect(
      icon: LucideIcons.checkCircle,
      title: 'Tests',
      description:
          'Mise en place d\'une suite de tests automatisés (unitaires, intégration, e2e) pour garantir la qualité du code.',
      color: const Color(0xFF06B6D4),
    ));

    // Déploiement
    if (platforme.contains('mobile')) {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.rocket,
        title: 'Déploiement',
        description:
            'CI/CD avec GitHub Actions, déploiement automatique sur Firebase App Distribution pour les tests, puis publication sur les stores.',
        color: const Color(0xFFEF4444),
      ));
    } else if (platforme.contains('web')) {
      aspects.add(_TechnicalAspect(
        icon: LucideIcons.rocket,
        title: 'Déploiement',
        description:
            'CI/CD avec GitHub Actions, déploiement automatique sur Vercel/Netlify avec prévisualisation des pull requests.',
        color: const Color(0xFFEF4444),
      ));
    }

    // Monitoring
    aspects.add(_TechnicalAspect(
      icon: LucideIcons.barChart,
      title: 'Monitoring',
      description:
          'Intégration d\'outils de monitoring (Sentry pour les erreurs, Analytics pour le suivi des performances).',
      color: const Color(0xFFEC4899),
    ));

    return aspects;
  }

  @override
  Widget build(BuildContext context) {
    final aspects = _getTechnicalAspects();

    return _SectionCard(
      title: 'Proposition technique',
      icon: LucideIcons.code,
      iconColor: AppColors.cyan400,
      isMobile: isMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: aspects.asMap().entries.map((entry) {
          final index = entry.key;
          final aspect = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < aspects.length - 1
                  ? Responsive.getResponsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    )
                  : 0,
            ),
            child: _TechnicalAspectCard(
              aspect: aspect,
              isMobile: isMobile,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Classe pour représenter un aspect technique
class _TechnicalAspect {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _TechnicalAspect({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// Carte pour chaque aspect technique
class _TechnicalAspectCard extends StatelessWidget {
  final _TechnicalAspect aspect;
  final bool isMobile;

  const _TechnicalAspectCard({
    required this.aspect,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 18.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            aspect.color.withOpacity(0.15),
            aspect.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: aspect.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: aspect.color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  aspect.color.withOpacity(0.3),
                  aspect.color.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: aspect.color.withOpacity(0.4),
              ),
            ),
            child: Icon(
              aspect.icon,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 24.0,
                tablet: 26.0,
                desktop: 28.0,
              ),
              color: aspect.color,
            ),
          ),
          SizedBox(
            width: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aspect.title,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 17.0,
                      tablet: 18.0,
                      desktop: 19.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
                Text(
                  aspect.description,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 15.0,
                      desktop: 16.0,
                    ),
                    color: AppColors.textCyan200.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Point technique
class _TechnicalPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isMobile;

  const _TechnicalPoint({
    required this.icon,
    required this.title,
    required this.description,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(
            Responsive.getResponsiveValue(
              context,
              mobile: 8.0,
              tablet: 10.0,
              desktop: 12.0,
            ),
          ),
          decoration: BoxDecoration(
            color: AppColors.cyan400.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: Responsive.getResponsiveValue(
              context,
              mobile: 18.0,
              tablet: 20.0,
              desktop: 22.0,
            ),
            color: AppColors.cyan400,
          ),
        ),
        SizedBox(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 15.0,
                    tablet: 16.0,
                    desktop: 17.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 4.0,
                  tablet: 6.0,
                  desktop: 8.0,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 13.0,
                    tablet: 14.0,
                    desktop: 15.0,
                  ),
                  color: AppColors.textCyan200.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Section: Comment travailler ce projet
class _HowToWorkSection extends StatelessWidget {
  final WorkProposal proposal;
  final ProjectAnalysis? analysis;
  final bool isMobile;

  const _HowToWorkSection({
    required this.proposal,
    this.analysis,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final content = analysis?.howToWork ?? 
        'Étudier en détail les fonctionnalités demandées et comprendre les objectifs du client. '
        'Créer un plan de développement détaillé avec les étapes, les ressources nécessaires et les délais. '
        'Travailler par sprints avec des livraisons régulières pour valider avec le client. '
        'Effectuer des tests complets et obtenir la validation finale du client avant la mise en production.';

    return _SectionCard(
      title: 'Comment travailler ce projet',
      icon: LucideIcons.lightbulb,
      iconColor: const Color(0xFFF59E0B),
      isMobile: isMobile,
      child: Text(
        content,
        style: TextStyle(
          fontSize: Responsive.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 15.0,
            desktop: 16.0,
          ),
          color: AppColors.textCyan200.withOpacity(0.9),
          height: 1.6,
        ),
      ),
    );
  }
}

// Section: Étapes de développement
class _DevelopmentStepsSection extends StatelessWidget {
  final WorkProposal proposal;
  final ProjectAnalysis? analysis;
  final bool isMobile;

  const _DevelopmentStepsSection({
    required this.proposal,
    this.analysis,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final steps = analysis?.developmentSteps ?? [];
    
    return _SectionCard(
      title: steps.isEmpty ? 'Fonctionnalités à développer' : 'Étapes de développement',
      icon: LucideIcons.listChecks,
      iconColor: const Color(0xFF10B981),
      isMobile: isMobile,
      child: steps.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: proposal.fonctionalite.split(', ').map((feature) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          top: Responsive.getResponsiveValue(
                            context,
                            mobile: 4.0,
                            tablet: 5.0,
                            desktop: 6.0,
                          ),
                        ),
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          feature.trim(),
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 15.0,
                              desktop: 16.0,
                            ),
                            color: AppColors.textWhite,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < steps.length - 1
                        ? Responsive.getResponsiveValue(
                            context,
                            mobile: 16.0,
                            tablet: 18.0,
                            desktop: 20.0,
                          )
                        : 0,
                  ),
                  child: _WorkStepItem(
                    step: index + 1,
                    title: step.title,
                    description: step.description,
                    icon: LucideIcons.checkCircle,
                    isMobile: isMobile,
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// Section: Recommandations
class _RecommendationsSection extends StatelessWidget {
  final WorkProposal proposal;
  final ProjectAnalysis? analysis;
  final bool isMobile;

  const _RecommendationsSection({
    required this.proposal,
    this.analysis,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = analysis?.recommendations ?? 
        'Maintenir une communication régulière avec le client pour s\'assurer que le projet répond à ses attentes. '
        'Utiliser un système de contrôle de version (Git) et documenter chaque étape importante du développement. '
        'Mettre en place des tests automatisés et des revues de code pour garantir la qualité du produit final.';

    return _SectionCard(
      title: 'Recommandations',
      icon: LucideIcons.star,
      iconColor: const Color(0xFFF59E0B),
      isMobile: isMobile,
      child: Text(
        recommendations,
        style: TextStyle(
          fontSize: Responsive.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 15.0,
            desktop: 16.0,
          ),
          color: AppColors.textCyan200.withOpacity(0.9),
          height: 1.6,
        ),
      ),
    );
  }
}

// Widget de chargement pour les sections
class _LoadingSection extends StatelessWidget {
  final String message;

  const _LoadingSection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCyan),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 15.0,
                  desktop: 16.0,
                ),
                color: AppColors.textCyan200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Composants réutilisables
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final bool isMobile;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderCyan,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  ),
                ),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 22.0,
                    desktop: 24.0,
                  ),
                ),
              ),
              SizedBox(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 22.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isMobile;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: Responsive.getResponsiveValue(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
          color: iconColor,
        ),
        SizedBox(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 13.0,
                    tablet: 14.0,
                    desktop: 15.0,
                  ),
                  color: AppColors.textCyan200.withOpacity(0.7),
                ),
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 4.0,
                  tablet: 6.0,
                  desktop: 8.0,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 15.0,
                    tablet: 16.0,
                    desktop: 17.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkStepItem extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final IconData icon;
  final bool isMobile;

  const _WorkStepItem({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 36.0,
            tablet: 40.0,
            desktop: 44.0,
          ),
          height: Responsive.getResponsiveValue(
            context,
            mobile: 36.0,
            tablet: 40.0,
            desktop: 44.0,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan400,
                AppColors.cyan400.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 22.0,
                    ),
                    color: AppColors.cyan400,
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 16.0,
                          tablet: 17.0,
                          desktop: 18.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 8.0,
                  desktop: 10.0,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                  color: AppColors.textCyan200.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMobile;

  const _RecommendationItem({
    required this.icon,
    required this.text,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: Responsive.getResponsiveValue(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
          color: const Color(0xFFF59E0B),
        ),
        SizedBox(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 15.0,
                desktop: 16.0,
              ),
              color: AppColors.textWhite,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
