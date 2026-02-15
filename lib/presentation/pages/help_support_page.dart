import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/l10n/app_strings.dart';
import '../widgets/navigation_bar.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final faqItems = [
      {
        'q': 'Comment modifier mon profil ?',
        'a': 'Allez dans Profil > Paramètres > Modifier le profil pour mettre à jour vos informations.',
      },
      {
        'q': 'Comment changer la langue ?',
        'a': 'Paramètres > Changer la langue, puis sélectionnez la langue souhaitée.',
      },
      {
        'q': 'Comment gérer les propositions de travail ?',
        'a': 'Utilisez l\'onglet Propositions dans la barre de navigation, ou le Dashboard depuis le profil.',
      },
      {
        'q': 'Comment nous contacter ?',
        'a': 'Envoyez un email au support ou utilisez le formulaire de contact ci-dessous.',
      },
    ];

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
                    _buildHeader(context, isMobile)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.1, end: 0, duration: 300.ms),
                    SizedBox(height: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
                    _buildSection(context, isMobile, LucideIcons.helpCircle, 'FAQ', faqItems
                        .map((e) => _FaqItem(question: e['q']!, answer: e['a']!))
                        .toList())
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 300.ms)
                        .slideY(begin: 0.05, end: 0, delay: 100.ms, duration: 300.ms),
                    SizedBox(height: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
                    _buildContactCard(context, isMobile)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 300.ms)
                        .slideY(begin: 0.05, end: 0, delay: 200.ms, duration: 300.ms),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan500.withOpacity(0.3),
                  AppColors.blue500.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.4), width: 1),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: AppColors.cyan400,
              size: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
            ),
          ),
        ),
        SizedBox(width: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(context, 'helpSupport'),
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 26.0, desktop: 30.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'FAQ et contact',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                  color: AppColors.textCyan200.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, bool isMobile, IconData icon, String title, List<_FaqItem> items) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.cyan400, size: 22),
                  SizedBox(width: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
              ...items.map((item) => Padding(
                    padding: EdgeInsets.only(bottom: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.question,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          item.answer,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                            color: AppColors.textCyan200.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan500.withOpacity(0.15),
            AppColors.blue500.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.mail, color: AppColors.cyan400, size: 22),
                  SizedBox(width: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                  Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              Text(
                'Pour toute question ou problème, contactez notre équipe support.',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                  color: AppColors.textCyan200.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
              Row(
                children: [
                  Icon(LucideIcons.mail, size: 18, color: AppColors.cyan400.withOpacity(0.9)),
                  SizedBox(width: 10),
                  Text(
                    'support@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cyan400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}
