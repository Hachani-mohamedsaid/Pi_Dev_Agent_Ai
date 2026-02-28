import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Agenda screen: review schedule / agenda. Placeholder for now.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 32.0, desktop: 48.0);

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
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 24, padding, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.chevronLeft, color: AppColors.cyan400, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(color: AppColors.cyan400, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, color: AppColors.cyan400, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Review Agenda',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your schedule and upcoming items',
                  style: TextStyle(color: AppColors.textCyan200.withOpacity(0.85), fontSize: 14),
                ),
                SizedBox(height: Responsive.getResponsiveValue(context, mobile: 28.0, tablet: 32.0, desktop: 40.0)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cyan500.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.calendarDays, color: AppColors.cyan400.withOpacity(0.7), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Agenda content will go here',
                        style: TextStyle(color: AppColors.textCyan200.withOpacity(0.9), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect your calendar or add meetings to see your agenda.',
                        style: TextStyle(color: AppColors.textCyan200.withOpacity(0.6), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
