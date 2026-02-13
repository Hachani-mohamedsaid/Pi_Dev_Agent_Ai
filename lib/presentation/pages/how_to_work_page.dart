import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/work_proposal_model.dart';
import '../../data/services/openai_analysis_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/app_colors.dart';

class HowToWorkPage extends StatefulWidget {
  final WorkProposal proposal;

  const HowToWorkPage({
    super.key,
    required this.proposal,
  });

  @override
  State<HowToWorkPage> createState() => _HowToWorkPageState();
}

class _HowToWorkPageState extends State<HowToWorkPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final OpenAIAnalysisService _analysisService = OpenAIAnalysisService();
  ProjectAnalysis? _analysis;
  bool _isLoading = true;

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
    _fadeController.forward();
    _slideController.forward();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      final analysis = await _analysisService.analyzeProject(widget.proposal);
      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                proposal: widget.proposal,
                isMobile: isMobile,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.cyan400,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chargement de l\'analyse...',
                              style: TextStyle(
                                color: AppColors.textCyan200,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _slideController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
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
                              _ContentCard(
                                analysis: _analysis,
                                proposal: widget.proposal,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
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

class _Header extends StatelessWidget {
  final WorkProposal proposal;
  final bool isMobile;
  final VoidCallback onBack;

  const _Header({
    required this.proposal,
    required this.isMobile,
    required this.onBack,
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
        vertical: Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: EdgeInsets.all(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
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
                  'Comment travailler',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 22.0,
                      tablet: 24.0,
                      desktop: 26.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  proposal.projectName,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ProjectAnalysis? analysis;
  final WorkProposal proposal;
  final bool isMobile;

  const _ContentCard({
    this.analysis,
    required this.proposal,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final content = analysis?.howToWork ??
        'Étudier en détail les fonctionnalités demandées et comprendre les objectifs du client. '
        'Créer un plan de développement détaillé avec les étapes, les ressources nécessaires et les délais. '
        'Travailler par sprints avec des livraisons régulières pour valider avec le client. '
        'Effectuer des tests complets et obtenir la validation finale du client avant la mise en production.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(
              Responsive.getResponsiveValue(
                context,
                mobile: 20.0,
                tablet: 24.0,
                desktop: 28.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.3),
                            const Color(0xFFF59E0B).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.lightbulb,
                        color: const Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Méthodologie de travail',
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
                          SizedBox(height: 4),
                          Text(
                            'Guide pour développer ce projet',
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
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 15.0,
                      tablet: 16.0,
                      desktop: 17.0,
                    ),
                    color: AppColors.textCyan200,
                    height: 1.8,
                  ),
                ),
                if (analysis?.developmentSteps != null &&
                    analysis!.developmentSteps.isNotEmpty) ...[
                  SizedBox(height: 32),
                  Text(
                    'Étapes de développement',
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
                  SizedBox(height: 16),
                  ...analysis!.developmentSteps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < analysis!.developmentSteps.length - 1
                            ? 20
                            : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cyan400,
                                  AppColors.cyan500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
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
                                SizedBox(height: 8),
                                Text(
                                  step.description,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 14.0,
                                      tablet: 15.0,
                                      desktop: 16.0,
                                    ),
                                    color: AppColors.textCyan200,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
