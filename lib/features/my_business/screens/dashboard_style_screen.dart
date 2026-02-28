import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../models/business_session.dart';

/// Second step: user picks a dashboard style. Then opens the dashboard.
class DashboardStyleScreen extends StatelessWidget {
  const DashboardStyleScreen({super.key, required this.websiteUrl});

  final String websiteUrl;

  static const List<Map<String, dynamic>> styles = [
    {'title': 'Vue Produits', 'subtitle': 'Produits, stock, prix. Idéal e-commerce.', 'icon': LucideIcons.package, 'color': Color(0xFF10B981)},
    {'title': 'Vue Analytique', 'subtitle': 'KPIs, graphiques, tendances.', 'icon': LucideIcons.barChart3, 'color': Color(0xFF3B82F6)},
    {'title': 'Vue Résumé', 'subtitle': 'Synthèse activité + insights IA.', 'icon': LucideIcons.sparkles, 'color': Color(0xFF8B5CF6)},
    {'title': 'Vue Complète', 'subtitle': 'Tout : produits, ventes, analytics.', 'icon': LucideIcons.layoutGrid, 'color': Color(0xFFEC4899)},
  ];

  void _openDashboard(BuildContext context, int styleIndex) {
    final session = BusinessSession(websiteUrl: websiteUrl, styleIndex: styleIndex);
    context.push('/my-business/dashboard', extra: session);
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0);
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('Style de dashboard'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/my-business');
                  }
                },
              ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, isMobile),
                      SizedBox(height: isMobile ? 24 : 28),
                      ...List.generate(styles.length, (i) => Padding(
                        padding: EdgeInsets.only(bottom: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
                        child: _buildStyleCard(context, isMobile, i),
                      )),
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisis un style',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
        Text(
          'Chaque style affiche tes données (produits, ventes, analytics) avec des mises en page différentes. L’IA te proposera des insights.',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
            color: AppColors.textCyan200.withOpacity(0.85),
            height: 1.4,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0, duration: 350.ms);
  }

  Widget _buildStyleCard(BuildContext context, bool isMobile, int index) {
    final style = styles[index];
    final color = style['color'] as Color;
    return GestureDetector(
      onTap: () => _openDashboard(context, index),
      child: Container(
        padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1e4a66).withOpacity(0.5),
              const Color(0xFF16384d).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: Responsive.getResponsiveValue(context, mobile: 52.0, tablet: 56.0, desktop: 60.0),
              height: Responsive.getResponsiveValue(context, mobile: 52.0, tablet: 56.0, desktop: 60.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
              ),
              child: Icon(style['icon'] as IconData, color: color, size: Responsive.getResponsiveValue(context, mobile: 26.0, tablet: 28.0, desktop: 30.0)),
            ),
            SizedBox(width: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style['title'] as String,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 17.0, desktop: 18.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style['subtitle'] as String,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 13.0, desktop: 14.0),
                      color: AppColors.textCyan200.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppColors.cyan400, size: Responsive.getResponsiveValue(context, mobile: 22.0, tablet: 24.0, desktop: 26.0)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + (index * 80)), duration: 400.ms).slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 100 + (index * 80)), duration: 400.ms);
  }
}
