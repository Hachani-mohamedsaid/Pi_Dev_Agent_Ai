import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final workPatterns = [
      {'emoji': '☀️', 'label': 'Most productive', 'value': '9:00-11:00 AM', 'confidence': 'High'},
      {'emoji': '🎯', 'label': 'Focus time needed', 'value': '2 hours/day', 'confidence': 'High'},
      {'emoji': '⏰', 'label': 'Preferred meeting time', 'value': '2:00-4:00 PM', 'confidence': 'Medium'},
      {'emoji': '🌙', 'label': 'Energy dip', 'value': '3:00-4:00 PM', 'confidence': 'High'},
    ];

    final communicationStyle = [
      {'emoji': '📧', 'label': 'Response time', 'value': 'Within 2 hours', 'confidence': 'High'},
      {'emoji': '💬', 'label': 'Preferred channel', 'value': 'Email > Slack', 'confidence': 'Medium'},
      {'emoji': '✍️', 'label': 'Message length', 'value': 'Concise', 'confidence': 'High'},
    ];

    final decisionPatterns = [
      {'emoji': '🎲', 'label': 'Risk tolerance', 'value': 'Moderate', 'confidence': 'Medium'},
      {'emoji': '🤔', 'label': 'Decision speed', 'value': 'Thoughtful', 'confidence': 'High'},
      {'emoji': '🙋', 'label': 'Delegation style', 'value': 'Collaborative', 'confidence': 'Medium'},
    ];

    final habits = [
      {'emoji': '☕', 'label': 'Coffee at 9 AM', 'frequency': 'Daily', 'icon': LucideIcons.coffee},
      {'emoji': '🏃', 'label': 'Gym on Tuesdays', 'frequency': 'Weekly', 'icon': LucideIcons.target},
      {'emoji': '📅', 'label': 'Friday afternoon buffer', 'frequency': 'Weekly', 'icon': LucideIcons.calendar},
    ];

    const accuracyScore = 87;

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

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Accuracy Score
                _buildAccuracyScore(context, isMobile, accuracyScore)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Work Patterns
                _buildSection(
                  context,
                  isMobile,
                  title: 'Work Patterns',
                  icon: LucideIcons.clock,
                  items: workPatterns,
                  startDelay: 200,
                ),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Communication Style
                _buildSection(
                  context,
                  isMobile,
                  title: 'Communication Style',
                  icon: LucideIcons.messageSquare,
                  items: communicationStyle,
                  startDelay: 500,
                ),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Decision Patterns
                _buildSection(
                  context,
                  isMobile,
                  title: 'Decision Patterns',
                  icon: LucideIcons.target,
                  items: decisionPatterns,
                  startDelay: 700,
                ),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Habits
                _buildHabitsSection(context, isMobile, habits)
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Timeline
                _buildTimeline(context, isMobile)
                    .animate()
                    .fadeIn(delay: 1300.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/insights'),
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
          'Insights',
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
          mobile: 6.0,
          tablet: 8.0,
          desktop: 10.0,
        )),
        Text(
          'What AVA has learned about you',
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
    );
  }

  Widget _buildAccuracyScore(BuildContext context, bool isMobile, int accuracyScore) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9333EA).withOpacity(0.1),
            AppColors.blue500.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Animated glow effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 0.6,
                      colors: [
                        const Color(0xFFA855F7).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 3000.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1, 1),
                      duration: 3000.ms,
                      curve: Curves.easeInOut,
                    )
                    .fade(
                      begin: 0.3,
                      end: 0.5,
                      duration: 3000.ms,
                    )
                    .then()
                    .fade(
                      begin: 0.5,
                      end: 0.3,
                      duration: 3000.ms,
                    ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 60.0,
                          tablet: 64.0,
                          desktop: 68.0,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 60.0,
                          tablet: 64.0,
                          desktop: 68.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9333EA).withOpacity(0.3),
                              AppColors.blue500.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 16.0,
                            tablet: 18.0,
                            desktop: 20.0,
                          )),
                          border: Border.all(
                            color: const Color(0xFF9333EA).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.brain,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 30.0,
                            tablet: 32.0,
                            desktop: 36.0,
                          ),
                          color: const Color(0xFFC084FC),
                        ),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      )),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AVA Accuracy',
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
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 4.0,
                            desktop: 5.0,
                          )),
                          Text(
                            'Prediction success rate',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 12.0,
                                tablet: 13.0,
                                desktop: 14.0,
                              ),
                              color: const Color(0xFFC084FC).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$accuracyScore%',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 32.0,
                            tablet: 36.0,
                            desktop: 40.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      )),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.trendingUp,
                            size: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 16.0,
                              desktop: 18.0,
                            ),
                            color: const Color(0xFF10B981),
                          ),
                          SizedBox(width: Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 4.0,
                            desktop: 5.0,
                          )),
                          Text(
                            '+5% this week',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 12.0,
                                tablet: 13.0,
                                desktop: 14.0,
                              ),
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    bool isMobile, {
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
    required int startDelay,
  }) {
    return Column(
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
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            )),
            Text(
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
          ],
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            child: _buildPatternCard(
              context,
              isMobile,
              emoji: item['emoji']!,
              label: item['label']!,
              value: item['value']!,
              confidence: item['confidence']!,
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: startDelay + (index * 100)), duration: 300.ms)
                .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: startDelay + (index * 100)), duration: 300.ms),
          );
        }),
      ],
    );
  }

  Widget _buildPatternCard(
    BuildContext context,
    bool isMobile, {
    required String emoji,
    required String label,
    required String value,
    required String confidence,
  }) {
    final isHighConfidence = confidence == 'High';
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 14.0,
        tablet: 16.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emoji,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 22.0,
                    tablet: 24.0,
                    desktop: 26.0,
                  ),
                ),
              ),
              SizedBox(width: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
                            ),
                            vertical: Responsive.getResponsiveValue(
                              context,
                              mobile: 2.0,
                              tablet: 3.0,
                              desktop: 4.0,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: isHighConfidence
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                              context,
                              mobile: 4.0,
                              tablet: 5.0,
                              desktop: 6.0,
                            )),
                            border: Border.all(
                              color: isHighConfidence
                                  ? const Color(0xFF10B981).withOpacity(0.2)
                                  : const Color(0xFFF59E0B).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            confidence,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 11.0,
                                desktop: 12.0,
                              ),
                              color: isHighConfidence
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFFCD34D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    )),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsSection(BuildContext context, bool isMobile, List<Map<String, dynamic>> habits) {
    return Column(
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
              color: AppColors.cyan400,
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            )),
            Text(
              'Recognized Habits',
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
          ],
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ...habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 20.0,
              )),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1e4a66).withOpacity(0.4),
                    const Color(0xFF16384d).withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                )),
                border: Border.all(
                  color: AppColors.cyan500.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                )),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
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
                          color: AppColors.cyan500.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 11.0,
                            desktop: 12.0,
                          )),
                        ),
                        child: Icon(
                          habit['icon'] as IconData,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 18.0,
                            tablet: 20.0,
                            desktop: 22.0,
                          ),
                          color: AppColors.cyan400,
                        ),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      )),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit['label'] as String,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 13.0,
                                  tablet: 14.0,
                                  desktop: 15.0,
                                ),
                                fontWeight: FontWeight.w500,
                                color: AppColors.textWhite,
                              ),
                            ),
                            SizedBox(height: Responsive.getResponsiveValue(
                              context,
                              mobile: 3.0,
                              tablet: 4.0,
                              desktop: 5.0,
                            )),
                            Text(
                              habit['frequency'] as String,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 11.0,
                                  tablet: 12.0,
                                  desktop: 13.0,
                                ),
                                color: AppColors.cyan400.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 1000 + (index * 100)), duration: 300.ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: Duration(milliseconds: 1000 + (index * 100)), duration: 300.ms),
          );
        }),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 14.0,
        tablet: 16.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Learning Evolution Timeline',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 11.0,
                desktop: 12.0,
              ),
              color: AppColors.cyan400.withOpacity(0.7),
            ),
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week 1',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 11.0,
                    desktop: 12.0,
                  ),
                  color: AppColors.cyan400.withOpacity(0.5),
                ),
              ),
              Text(
                'Week 2',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 11.0,
                    desktop: 12.0,
                  ),
                  color: AppColors.cyan400.withOpacity(0.5),
                ),
              ),
              Text(
                'Week 3 (Now)',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 11.0,
                    desktop: 12.0,
                  ),
                  color: AppColors.cyan400,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          )),
          Container(
            height: Responsive.getResponsiveValue(
              context,
              mobile: 4.0,
              tablet: 5.0,
              desktop: 6.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.cyan500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                context,
                mobile: 2.0,
                tablet: 2.5,
                desktop: 3.0,
              )),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                context,
                mobile: 2.0,
                tablet: 2.5,
                desktop: 3.0,
              )),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan500,
                          AppColors.blue500,
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1500.ms, duration: 1000.ms),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
