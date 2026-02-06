import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final goals = [
      {
        'id': 1,
        'title': 'Complete Q1 Project',
        'category': 'Work',
        'progress': 75,
        'deadline': 'Mar 31',
        'dailyActions': ['Review design specs', 'Update stakeholders'],
        'streak': 12,
      },
      {
        'id': 2,
        'title': 'Improve Work-Life Balance',
        'category': 'Personal',
        'progress': 60,
        'deadline': 'Ongoing',
        'dailyActions': ['Take lunch break', 'No meetings after 5 PM'],
        'streak': 8,
      },
      {
        'id': 3,
        'title': 'Learn React Native',
        'category': 'Learning',
        'progress': 40,
        'deadline': 'Apr 30',
        'dailyActions': ['30 min daily practice', 'Build one component'],
        'streak': 5,
      },
    ];

    final achievements = [
      {'icon': '🏆', 'title': '7-day streak', 'date': 'Yesterday'},
      {'icon': '⚡', 'title': '50 tasks completed', 'date': 'This week'},
      {'icon': '🎯', 'title': 'Goal achieved', 'date': 'Last week'},
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

                // Add Goal Button
                _buildNewGoalButton(context, isMobile)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Active Goals
                ...goals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final goal = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                    ),
                    child: _buildGoalCard(context, isMobile, goal, index)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms),
                  );
                }),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Achievements
                _buildAchievementsSection(context, isMobile, achievements)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/goals'),
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
          'Goals',
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
          'Track your personal and professional growth',
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

  Widget _buildNewGoalButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () {
        // Handle new goal
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
          gradient: LinearGradient(
            colors: [
              AppColors.cyan500.withOpacity(0.3),
              AppColors.blue500.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          )),
          border: Border.all(
            color: AppColors.cyan500.withOpacity(0.5),
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
              color: AppColors.textCyan300,
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            )),
            Text(
              'New Goal',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 13.0,
                  tablet: 14.0,
                  desktop: 15.0,
                ),
                fontWeight: FontWeight.w600,
                color: AppColors.textCyan300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, bool isMobile, Map<String, dynamic> goal, int index) {
    final progress = goal['progress'] as int;
    final dailyActions = goal['dailyActions'] as List<String>;
    final streak = goal['streak'] as int;

    return Container(
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
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Progress
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['title'] as String,
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
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 4.0,
                          tablet: 5.0,
                          desktop: 6.0,
                        )),
                        Row(
                          children: [
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
                                  mobile: 3.0,
                                  tablet: 4.0,
                                  desktop: 5.0,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                border: Border.all(
                                  color: AppColors.cyan500.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                goal['category'] as String,
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
                            ),
                            SizedBox(width: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
                            )),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.calendar,
                                  size: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  color: AppColors.cyan400.withOpacity(0.6),
                                ),
                                SizedBox(width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 3.0,
                                  tablet: 4.0,
                                  desktop: 5.0,
                                )),
                                Text(
                                  goal['deadline'] as String,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 11.0,
                                      desktop: 12.0,
                                    ),
                                    color: AppColors.cyan400.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$progress%',
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
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 2.0,
                        tablet: 3.0,
                        desktop: 4.0,
                      )),
                      Text(
                        'Complete',
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
                ],
              ),

              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              )),

              // Progress Bar
              Container(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 7.0,
                  desktop: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 3.0,
                    tablet: 3.5,
                    desktop: 4.0,
                  )),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 3.0,
                    tablet: 3.5,
                    desktop: 4.0,
                  )),
                  child: FractionallySizedBox(
                    widthFactor: progress / 100,
                    alignment: Alignment.centerLeft,
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
                        .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)), duration: 1000.ms),
                  ),
                ),
              ),

              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              )),

              // Daily Actions
              Text(
                'Today\'s Actions',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 11.0,
                    tablet: 12.0,
                    desktop: 13.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan400,
                ),
              ),
              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              )),
              ...dailyActions.map((action) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                        color: const Color(0xFF10B981),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 6.0,
                        tablet: 8.0,
                        desktop: 10.0,
                      )),
                      Text(
                        action,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          ),
                          color: AppColors.textCyan200.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              )),

              // Streak
              Container(
                padding: EdgeInsets.only(
                  top: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  ),
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.cyan500.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.award,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                      color: const Color(0xFFFCD34D),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    Text(
                      '$streak day streak!',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFCD34D),
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

  Widget _buildAchievementsSection(BuildContext context, bool isMobile, List<Map<String, String>> achievements) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 18.0,
        tablet: 20.0,
        desktop: 24.0,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.award,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 22.0,
                    ),
                    color: const Color(0xFFC084FC),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  )),
                  Text(
                    'Recent Achievements',
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
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              )),
              ...achievements.map((achievement) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        achievement['icon']!,
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
                            Text(
                              achievement['title']!,
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
                              achievement['date']!,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 11.0,
                                  tablet: 12.0,
                                  desktop: 13.0,
                                ),
                                color: const Color(0xFFC084FC).withOpacity(0.6),
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
          ),
        ),
      ),
    );
  }
}
