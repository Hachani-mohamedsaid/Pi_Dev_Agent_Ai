import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

Color _primaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textWhite
      : const Color(0xFF12263A);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textCyan200
      : const Color(0xFF5B7B92);
}

/// Agenda screen: review schedule / agenda. Placeholder for now.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 48.0,
    );
    final pageGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FCFF), Color(0xFFEAF4FB), Color(0xFFF3F8FC)],
          );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(gradient: pageGradient),
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
                      Icon(
                        LucideIcons.chevronLeft,
                        color: AppColors.cyan400,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(
                          color: AppColors.cyan400,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      color: AppColors.cyan400,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Review Agenda',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 24.0,
                          tablet: 28.0,
                          desktop: 32.0,
                        ),
                        fontWeight: FontWeight.bold,
                        color: _primaryText(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your schedule and upcoming items',
                  style: TextStyle(
                    color: _secondaryText(context).withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveValue(
                    context,
                    mobile: 28.0,
                    tablet: 32.0,
                    desktop: 40.0,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : const Color(0xFFF9FCFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cyan500.withOpacity(0.25)
                          : const Color(0xFFC7DDE9),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.calendarDays,
                        color: AppColors.cyan400.withOpacity(0.7),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Agenda content will go here',
                        style: TextStyle(
                          color: _primaryText(context),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect your calendar or add meetings to see your agenda.',
                        style: TextStyle(
                          color: _secondaryText(context).withOpacity(0.8),
                          fontSize: 13,
                        ),
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
