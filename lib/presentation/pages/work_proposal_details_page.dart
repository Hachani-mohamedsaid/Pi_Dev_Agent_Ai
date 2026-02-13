import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/work_proposal_model.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/app_colors.dart';

class WorkProposalDetailsPage extends StatelessWidget {
  final WorkProposal proposal;

  const WorkProposalDetailsPage({
    super.key,
    required this.proposal,
  });

  Map<String, dynamic> _getProjectTypeColors(String typeProjet) {
    final lowerType = typeProjet.toLowerCase();
    if (lowerType.contains('mobile') || lowerType.contains('app')) {
      return {
        'bg': [
          const Color(0xFF9333EA).withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ],
        'text': const Color(0xFFC084FC),
        'border': const Color(0xFF9333EA).withOpacity(0.3),
        'icon': LucideIcons.smartphone,
      };
    } else if (lowerType.contains('web') || lowerType.contains('site')) {
      return {
        'bg': [
          AppColors.cyan500.withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ],
        'text': AppColors.cyan400,
        'border': AppColors.cyan500.withOpacity(0.3),
        'icon': LucideIcons.globe,
      };
    } else if (lowerType.contains('api')) {
      return {
        'bg': [
          const Color(0xFF10B981).withOpacity(0.2),
          AppColors.cyan500.withOpacity(0.2),
        ],
        'text': const Color(0xFF10B981),
        'border': const Color(0xFF10B981).withOpacity(0.3),
        'icon': LucideIcons.code,
      };
    }
    return {
      'bg': [
        AppColors.cyan500.withOpacity(0.2),
        AppColors.blue500.withOpacity(0.2),
      ],
      'text': AppColors.cyan400,
      'border': AppColors.cyan500.withOpacity(0.3),
      'icon': LucideIcons.briefcase,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
    final projectColors = _getProjectTypeColors(proposal.typeProjet);

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
          bottom: false,
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: padding,
                  bottom: Responsive.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 140.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _Header(
                      proposal: proposal,
                      isMobile: isMobile,
                      projectColors: projectColors,
                      onBack: () => context.pop(),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.2, end: 0, duration: 500.ms),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),

                    // Detail Cards
                    _DetailCard(
                      title: 'Client',
                      icon: LucideIcons.user,
                      iconColor: AppColors.cyan400,
                      gradient: [
                        AppColors.cyan500.withOpacity(0.2),
                        AppColors.blue500.withOpacity(0.2),
                      ],
                      children: [
                        _DetailItem(
                          label: 'Nom',
                          value: proposal.clientName,
                          icon: LucideIcons.user,
                          isMobile: isMobile,
                        ),
                        _DetailItem(
                          label: 'Email',
                          value: proposal.clientEmail,
                          icon: LucideIcons.mail,
                          isMobile: isMobile,
                        ),
                      ],
                      isMobile: isMobile,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 300.ms),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    )),

                    _DetailCard(
                      title: 'Projet',
                      icon: projectColors['icon'] as IconData,
                      iconColor: projectColors['text'] as Color,
                      gradient: projectColors['bg'] as List<Color>,
                      children: [
                        _DetailItem(
                          label: 'Type',
                          value: proposal.typeProjet,
                          icon: LucideIcons.briefcase,
                          isMobile: isMobile,
                        ),
                        _DetailItem(
                          label: 'Secteur',
                          value: proposal.secteur,
                          icon: LucideIcons.building,
                          isMobile: isMobile,
                        ),
                        _DetailItem(
                          label: 'Plateforme',
                          value: proposal.platforme,
                          icon: LucideIcons.monitor,
                          isMobile: isMobile,
                        ),
                        _DetailItem(
                          label: 'Complexité',
                          value: proposal.niveauComplexite,
                          icon: LucideIcons.activity,
                          isMobile: isMobile,
                        ),
                      ],
                      isMobile: isMobile,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 300.ms),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    )),

                    _DetailCard(
                      title: 'Budget et délai',
                      icon: LucideIcons.euro,
                      iconColor: AppColors.statusAccepted,
                      gradient: [
                        AppColors.statusAccepted.withOpacity(0.2),
                        AppColors.statusPending.withOpacity(0.2),
                      ],
                      children: [
                        _DetailItem(
                          label: 'Budget estimé',
                          value: '${proposal.budgetEstime.toStringAsFixed(0)} €',
                          icon: LucideIcons.dollarSign,
                          isMobile: isMobile,
                        ),
                        _DetailItem(
                          label: 'Délai estimé',
                          value: proposal.deadlineEstime,
                          icon: LucideIcons.calendar,
                          isMobile: isMobile,
                        ),
                      ],
                      isMobile: isMobile,
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 300.ms),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    )),

                    _DetailCard(
                      title: 'Fonctionnalités',
                      icon: LucideIcons.listChecks,
                      iconColor: AppColors.cyan400,
                      gradient: [
                        AppColors.cyan500.withOpacity(0.2),
                        AppColors.blue500.withOpacity(0.2),
                      ],
                      children: [
                        Container(
                          padding: EdgeInsets.all(Responsive.getResponsiveValue(
                            context,
                            mobile: 18.0,
                            tablet: 20.0,
                            desktop: 24.0,
                          )),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryMedium.withOpacity(0.4),
                                AppColors.primaryDarker.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 16.0,
                              desktop: 18.0,
                            )),
                            border: Border.all(
                              color: AppColors.cyan500.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            proposal.fonctionalite.isNotEmpty
                                ? proposal.fonctionalite
                                : 'Aucune fonctionnalité spécifiée',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 15.0,
                                tablet: 16.0,
                                desktop: 17.0,
                              ),
                              color: AppColors.textCyan200,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      isMobile: isMobile,
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 300.ms),
                  ],
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
  final Map<String, dynamic> projectColors;
  final VoidCallback onBack;

  const _Header({
    required this.proposal,
    required this.isMobile,
    required this.projectColors,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                )),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cyan500.withOpacity(0.3),
                      AppColors.blue500.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  )),
                  border: Border.all(
                    color: AppColors.cyan500.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.cyan400,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 22.0,
                    desktop: 24.0,
                  ),
                ),
              ),
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails de la proposition',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 26.0,
                        tablet: 28.0,
                        desktop: 32.0,
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: Responsive.getResponsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  )),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        )),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: projectColors['bg'] as List<Color>,
                          ),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          )),
                          border: Border.all(
                            color: projectColors['border'] as Color,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          projectColors['icon'] as IconData,
                          color: projectColors['text'] as Color,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      Expanded(
                        child: Text(
                          proposal.projectName,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 15.0,
                              tablet: 16.0,
                              desktop: 17.0,
                            ),
                            color: AppColors.textCyan200.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final List<Widget> children;
  final bool isMobile;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.children,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.5),
            AppColors.primaryDarker.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 22.0,
          desktop: 24.0,
        )),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 22.0,
          desktop: 24.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(
              context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: Responsive.getResponsiveValue(
                        context,
                        mobile: 52.0,
                        tablet: 56.0,
                        desktop: 60.0,
                      ),
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 52.0,
                        tablet: 56.0,
                        desktop: 60.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        )),
                        border: Border.all(
                          color: iconColor.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 26.0,
                          tablet: 28.0,
                          desktop: 30.0,
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    )),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 22.0,
                            tablet: 24.0,
                            desktop: 26.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 24.0,
                  tablet: 26.0,
                  desktop: 28.0,
                )),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isMobile;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 14.0,
          desktop: 16.0,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryMedium.withOpacity(0.4),
              AppColors.primaryDarker.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 16.0,
            desktop: 18.0,
          )),
          border: Border.all(
            color: AppColors.cyan500.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan500.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Responsive.getResponsiveValue(
                context,
                mobile: 44.0,
                tablet: 48.0,
                desktop: 52.0,
              ),
              height: Responsive.getResponsiveValue(
                context,
                mobile: 44.0,
                tablet: 48.0,
                desktop: 52.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan500.withOpacity(0.2),
                    AppColors.blue500.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                )),
                border: Border.all(
                  color: AppColors.cyan500.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
                color: AppColors.cyan400,
              ),
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 11.0,
                        tablet: 12.0,
                        desktop: 13.0,
                      ),
                      color: AppColors.textCyan200.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  )),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 17.0,
                        desktop: 18.0,
                      ),
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
