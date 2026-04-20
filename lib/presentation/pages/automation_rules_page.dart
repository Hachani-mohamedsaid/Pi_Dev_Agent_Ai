import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

class AutomationRule {
  final int id;
  final String name;
  final String trigger;
  final String action;
  final String category;
  final bool enabled;
  final IconData icon;

  AutomationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.action,
    required this.category,
    required this.enabled,
    required this.icon,
  });
}

class AutomationRulesPage extends StatefulWidget {
  const AutomationRulesPage({super.key});

  @override
  State<AutomationRulesPage> createState() => _AutomationRulesPageState();
}

class _AutomationRulesPageState extends State<AutomationRulesPage> {
  List<bool> _rulesEnabled = [true, true, true, false];

  List<AutomationRule> _getRules(BuildContext context) {
    return [
      AutomationRule(
        id: 1,
        name: AppStrings.tr(context, 'declineLateMeetings'),
        trigger: AppStrings.tr(context, 'meetingAfter6PM'),
        action: AppStrings.tr(context, 'autoDeclineTemplate'),
        category: AppStrings.tr(context, 'calendar'),
        enabled: _rulesEnabled[0],
        icon: LucideIcons.calendar,
      ),
      AutomationRule(
        id: 2,
        name: AppStrings.tr(context, 'autoReplyNewsletters'),
        trigger: AppStrings.tr(context, 'emailCategoryNewsletter'),
        action: AppStrings.tr(context, 'archiveMarkRead'),
        category: AppStrings.tr(context, 'emailCategory'),
        enabled: _rulesEnabled[1],
        icon: LucideIcons.mail,
      ),
      AutomationRule(
        id: 3,
        name: AppStrings.tr(context, 'uberBudgetLimit'),
        trigger: AppStrings.tr(context, 'rideCostOver50'),
        action: AppStrings.tr(context, 'requestConfirmation'),
        category: AppStrings.tr(context, 'travel'),
        enabled: _rulesEnabled[2],
        icon: LucideIcons.dollarSign,
      ),
      AutomationRule(
        id: 4,
        name: AppStrings.tr(context, 'morningMeetingBuffer'),
        trigger: AppStrings.tr(context, 'meetingBefore10AM'),
        action: AppStrings.tr(context, 'suggestReschedule10AM'),
        category: AppStrings.tr(context, 'calendar'),
        enabled: _rulesEnabled[3],
        icon: LucideIcons.calendar,
      ),
    ];
  }

  Map<String, dynamic> _getCategoryColors(
    BuildContext context,
    String category,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (category) {
      case 'Calendar':
        return {
          'bg': isDark
              ? [
                  const Color(0xFF9333EA).withOpacity(0.2),
                  AppColors.blue500.withOpacity(0.2),
                ]
              : [const Color(0xFFE9D5FF), const Color(0xFFDBEAFE)],
          'text': isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
          'border': isDark
              ? const Color(0xFF9333EA).withOpacity(0.3)
              : const Color(0xFF7C3AED).withOpacity(0.18),
        };
      case 'Email':
        return {
          'bg': isDark
              ? [
                  AppColors.cyan500.withOpacity(0.2),
                  AppColors.blue500.withOpacity(0.2),
                ]
              : [const Color(0xFFCFFAFE), const Color(0xFFDBEAFE)],
          'text': isDark ? AppColors.cyan400 : const Color(0xFF0891B2),
          'border': isDark
              ? AppColors.cyan500.withOpacity(0.3)
              : const Color(0xFF06B6D4).withOpacity(0.18),
        };
      case 'Travel':
        return {
          'bg': isDark
              ? [
                  const Color(0xFFFFB800).withOpacity(0.2),
                  const Color(0xFFFF9800).withOpacity(0.2),
                ]
              : [const Color(0xFFFFF7CD), const Color(0xFFFFEDD5)],
          'text': isDark ? const Color(0xFFFFD93D) : const Color(0xFFCA8A04),
          'border': isDark
              ? const Color(0xFFFFB800).withOpacity(0.3)
              : const Color(0xFFCA8A04).withOpacity(0.18),
        };
      default:
        return {
          'bg': isDark
              ? [
                  AppColors.cyan500.withOpacity(0.2),
                  AppColors.blue500.withOpacity(0.2),
                ]
              : [const Color(0xFFCFFAFE), const Color(0xFFDBEAFE)],
          'text': isDark ? AppColors.cyan400 : const Color(0xFF0891B2),
          'border': isDark
              ? AppColors.cyan500.withOpacity(0.3)
              : const Color(0xFF06B6D4).withOpacity(0.18),
        };
    }
  }

  void _toggleRule(int id) {
    setState(() {
      if (id >= 1 && id <= _rulesEnabled.length) {
        _rulesEnabled[id - 1] = !_rulesEnabled[id - 1];
      }
    });
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0f2940),
                    Color(0xFF1a3a52),
                    Color(0xFF0f2940),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFF7FC),
                    Color(0xFFF6FBFF),
                    Color(0xFFEFF7FC),
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
                  ), // Space for navigation bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, isMobile)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.2, end: 0, duration: 500.ms),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Create New Rule Button
                    _buildCreateButton(context, isMobile)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 300.ms)
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1, 1),
                          delay: 100.ms,
                          duration: 300.ms,
                        ),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Rules List
                    _buildRulesList(context, isMobile),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Rule Templates
                    _buildRuleTemplates(context, isMobile)
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 300.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 600.ms,
                          duration: 300.ms,
                        ),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Info
                    _buildInfo(
                      context,
                      isMobile,
                    ).animate().fadeIn(delay: 800.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/automation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr(context, 'automationRules'),
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 26.0,
              tablet: 28.0,
              desktop: 32.0,
            ),
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textWhite : const Color(0xFF11263A),
          ),
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
          AppStrings.tr(context, 'teachAvaPreferences'),
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 13.0,
              tablet: 14.0,
              desktop: 15.0,
            ),
            color: isDark
                ? AppColors.textCyan200.withOpacity(0.7)
                : const Color(0xFF0891B2),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        // Handle create new rule
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.getResponsiveValue(
            context,
            mobile: 11.0,
            tablet: 12.0,
            desktop: 14.0,
          ),
        ),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    AppColors.cyan500.withOpacity(0.3),
                    AppColors.blue500.withOpacity(0.3),
                  ],
                )
              : LinearGradient(
                  colors: [const Color(0xFFBAE6FD), const Color(0xFFDBEAFE)],
                ),
          borderRadius: BorderRadius.circular(
            Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 13.0,
              desktop: 14.0,
            ),
          ),
          border: Border.all(
            color: isDark
                ? AppColors.cyan500.withOpacity(0.5)
                : const Color(0xFF06B6D4).withOpacity(0.18),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 18.0,
                tablet: 20.0,
                desktop: 22.0,
              ),
              color: isDark ? AppColors.textCyan300 : const Color(0xFF0891B2),
            ),
            SizedBox(
              width: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            Text(
              AppStrings.tr(context, 'createNewRule'),
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 13.0,
                  tablet: 14.0,
                  desktop: 15.0,
                ),
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textCyan300 : const Color(0xFF0891B2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesList(BuildContext context, bool isMobile) {
    final rules = _getRules(context);
    return Column(
      children: rules.asMap().entries.map((entry) {
        final index = entry.key;
        final rule = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildRuleCard(context, isMobile, rule, index),
        );
      }).toList(),
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    bool isMobile,
    AutomationRule rule,
    int index,
  ) {
    final colors = _getCategoryColors(context, rule.category);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
          padding: EdgeInsets.all(
            Responsive.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
          ),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1e4a66), Color(0xFF16384d)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF6FBFF), Color(0xFFE9F4FB)],
                  ),
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
            border: Border.all(
              color: rule.enabled
                  ? (isDark
                        ? AppColors.cyan500.withOpacity(0.1)
                        : const Color(0xFF06B6D4).withOpacity(0.10))
                  : (isDark
                        ? AppColors.cyan500.withOpacity(0.05)
                        : const Color(0xFF06B6D4).withOpacity(0.05)),
              width: 1,
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
              child: Opacity(
                opacity: rule.enabled ? 1.0 : 0.6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
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
                          colors: colors['bg'] as List<Color>,
                        ),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 11.0,
                            desktop: 12.0,
                          ),
                        ),
                        border: Border.all(
                          color: colors['border'] as Color,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        rule.icon,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 22.0,
                          tablet: 24.0,
                          desktop: 26.0,
                        ),
                        color: colors['text'] as Color,
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
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rule.name,
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
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            Responsive.getResponsiveValue(
                                              context,
                                              mobile: 6.0,
                                              tablet: 8.0,
                                              desktop: 10.0,
                                            ),
                                        vertical: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 3.0,
                                          tablet: 4.0,
                                          desktop: 5.0,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: colors['bg'] as List<Color>,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.getResponsiveValue(
                                            context,
                                            mobile: 4.0,
                                            tablet: 5.0,
                                            desktop: 6.0,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: colors['border'] as Color,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        rule.category,
                                        style: TextStyle(
                                          fontSize:
                                              Responsive.getResponsiveValue(
                                                context,
                                                mobile: 10.0,
                                                tablet: 11.0,
                                                desktop: 12.0,
                                              ),
                                          color: colors['text'] as Color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Toggle
                              GestureDetector(
                                onTap: () => _toggleRule(rule.id),
                                child: Container(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 44.0,
                                    tablet: 48.0,
                                    desktop: 52.0,
                                  ),
                                  height: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 22.0,
                                    tablet: 24.0,
                                    desktop: 26.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rule.enabled
                                        ? AppColors.cyan500
                                        : AppColors.textWhite.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      Responsive.getResponsiveValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 13.0,
                                        desktop: 14.0,
                                      ),
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedPositioned(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        left: rule.enabled
                                            ? Responsive.getResponsiveValue(
                                                context,
                                                mobile: 24.0,
                                                tablet: 26.0,
                                                desktop: 28.0,
                                              )
                                            : Responsive.getResponsiveValue(
                                                context,
                                                mobile: 2.0,
                                                tablet: 2.0,
                                                desktop: 2.0,
                                              ),
                                        top: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 2.0,
                                          tablet: 2.0,
                                          desktop: 2.0,
                                        ),
                                        child: Container(
                                          width: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 18.0,
                                            tablet: 20.0,
                                            desktop: 22.0,
                                          ),
                                          height: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 18.0,
                                            tablet: 20.0,
                                            desktop: 22.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.textWhite,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Responsive.getResponsiveValue(
                              context,
                              mobile: 10.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                          // Trigger & Action
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.tr(context, 'when'),
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.cyan400.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 6.0,
                                  tablet: 8.0,
                                  desktop: 10.0,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rule.trigger,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 11.0,
                                      tablet: 12.0,
                                      desktop: 13.0,
                                    ),
                                    color: AppColors.textCyan200.withOpacity(
                                      0.6,
                                    ),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.tr(context, 'then'),
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.cyan400.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 6.0,
                                  tablet: 8.0,
                                  desktop: 10.0,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rule.action,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 11.0,
                                      tablet: 12.0,
                                      desktop: 13.0,
                                    ),
                                    color: AppColors.textCyan200.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Responsive.getResponsiveValue(
                              context,
                              mobile: 10.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Handle edit
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 7.0,
                                        tablet: 8.0,
                                        desktop: 9.0,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan500.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.getResponsiveValue(
                                          context,
                                          mobile: 8.0,
                                          tablet: 9.0,
                                          desktop: 10.0,
                                        ),
                                      ),
                                      border: Border.all(
                                        color: AppColors.cyan500.withOpacity(
                                          0.2,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.edit,
                                          size: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 12.0,
                                            tablet: 13.0,
                                            desktop: 14.0,
                                          ),
                                          color: AppColors.cyan400,
                                        ),
                                        SizedBox(
                                          width: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 4.0,
                                            tablet: 5.0,
                                            desktop: 6.0,
                                          ),
                                        ),
                                        Text(
                                          AppStrings.tr(context, 'edit'),
                                          style: TextStyle(
                                            fontSize:
                                                Responsive.getResponsiveValue(
                                                  context,
                                                  mobile: 11.0,
                                                  tablet: 12.0,
                                                  desktop: 13.0,
                                                ),
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.cyan400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 6.0,
                                  tablet: 8.0,
                                  desktop: 10.0,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Handle delete
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 12.0,
                                      desktop: 14.0,
                                    ),
                                    vertical: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 7.0,
                                      tablet: 8.0,
                                      desktop: 9.0,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF0000,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      Responsive.getResponsiveValue(
                                        context,
                                        mobile: 8.0,
                                        tablet: 9.0,
                                        desktop: 10.0,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF0000,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.trash2,
                                    size: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0,
                                    ),
                                    color: const Color(0xFFFF6B6B),
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
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + (index * 100)),
          duration: 300.ms,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          delay: Duration(milliseconds: 100 + (index * 100)),
          duration: 300.ms,
        );
  }

  Widget _buildRuleTemplates(BuildContext context, bool isMobile) {
    final templates = [
      'Auto-schedule focus time blocks',
      'Filter low-priority emails',
      'Smart meeting clustering',
      'Automatic travel time buffers',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        gradient: isDark
            ? LinearGradient(
                colors: [
                  const Color(0xFF9333EA).withOpacity(0.1),
                  AppColors.blue500.withOpacity(0.1),
                ],
              )
            : LinearGradient(
                colors: [const Color(0xFFE9D5FF), const Color(0xFFDBEAFE)],
              ),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          ),
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF9333EA).withOpacity(0.2)
              : const Color(0xFF7C3AED).withOpacity(0.18),
          width: 1,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.zap,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 22.0,
                    ),
                    color: isDark
                        ? const Color(0xFFC084FC)
                        : const Color(0xFF7C3AED),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                  ),
                  Text(
                    'Popular Rule Templates',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 15.0,
                        tablet: 16.0,
                        desktop: 17.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textWhite
                          : const Color(0xFF11263A),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
              ...templates.map((template) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Handle template selection
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                        vertical: Responsive.getResponsiveValue(
                          context,
                          mobile: 7.0,
                          tablet: 8.0,
                          desktop: 9.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.textWhite.withOpacity(0.05)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 8.0,
                            tablet: 9.0,
                            desktop: 10.0,
                          ),
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.textWhite.withOpacity(0.1)
                              : const Color(0xFF7DD3FC).withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '+',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                                tablet: 15.0,
                                desktop: 16.0,
                              ),
                              color: isDark
                                  ? AppColors.textCyan200.withOpacity(0.7)
                                  : const Color(0xFF0891B2),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              template,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 13.0,
                                  desktop: 14.0,
                                ),
                                color: isDark
                                    ? AppColors.textCyan200.withOpacity(0.7)
                                    : const Color(0xFF0891B2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 14.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cyan500.withOpacity(0.05)
            : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
        ),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withOpacity(0.1)
              : const Color(0xFF06B6D4).withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Text(
        'Rules help AVA understand your boundaries and preferences. All rules can be edited or disabled anytime.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: Responsive.getResponsiveValue(
            context,
            mobile: 10.0,
            tablet: 11.0,
            desktop: 12.0,
          ),
          color: isDark
              ? AppColors.cyan400.withOpacity(0.7)
              : const Color(0xFF0891B2),
        ),
      ),
    );
  }
}
