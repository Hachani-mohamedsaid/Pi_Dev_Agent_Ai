import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum SuggestionType { time, location, calendar, weather, energy }
enum SuggestionPriority { high, medium, low }

class Suggestion {
  final int id;
  final SuggestionType type;
  final String title;
  final String description;
  final IconData icon;
  final String context;
  final SuggestionPriority priority;
  final List<SuggestionAction>? actions;

  Suggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.context,
    required this.priority,
    this.actions,
  });
}

class SuggestionAction {
  final String label;
  final bool isPrimary;

  SuggestionAction({
    required this.label,
    required this.isPrimary,
  });
}

class SuggestionsFeedPage extends StatefulWidget {
  const SuggestionsFeedPage({super.key});

  @override
  State<SuggestionsFeedPage> createState() => _SuggestionsFeedPageState();
}

class _SuggestionsFeedPageState extends State<SuggestionsFeedPage> {
  final List<int> _dismissedSuggestions = [];

  final List<Suggestion> _suggestions = [
    Suggestion(
      id: 1,
      type: SuggestionType.time,
      title: 'Good morning! Start with emails or coffee first?',
      description: 'Based on your morning routine',
      icon: LucideIcons.coffee,
      context: '8:30 AM',
      priority: SuggestionPriority.high,
      actions: [
        SuggestionAction(label: 'Check emails', isPrimary: true),
        SuggestionAction(label: 'Order coffee', isPrimary: false),
      ],
    ),
    Suggestion(
      id: 2,
      type: SuggestionType.calendar,
      title: 'Leave now to arrive on time',
      description: 'Meeting at 10:00 AM, 15 min drive',
      icon: LucideIcons.navigation,
      context: 'In 30 minutes',
      priority: SuggestionPriority.high,
      actions: [
        SuggestionAction(label: 'Start navigation', isPrimary: true),
        SuggestionAction(label: 'Reschedule', isPrimary: false),
      ],
    ),
    Suggestion(
      id: 3,
      type: SuggestionType.weather,
      title: 'Bring umbrella, leave 10 min early',
      description: 'Rain forecast at 9:00 AM',
      icon: LucideIcons.umbrella,
      context: 'Weather alert',
      priority: SuggestionPriority.medium,
      actions: [
        SuggestionAction(label: 'Got it', isPrimary: true),
      ],
    ),
    Suggestion(
      id: 4,
      type: SuggestionType.location,
      title: 'Want your usual order?',
      description: "You're near your favorite coffee shop",
      icon: LucideIcons.mapPin,
      context: 'Location-based',
      priority: SuggestionPriority.medium,
      actions: [
        SuggestionAction(label: 'Order now', isPrimary: true),
        SuggestionAction(label: 'Not now', isPrimary: false),
      ],
    ),
    Suggestion(
      id: 5,
      type: SuggestionType.energy,
      title: 'Take a 15-min break?',
      description: "You've been focused for 2 hours",
      icon: LucideIcons.battery,
      context: 'Energy management',
      priority: SuggestionPriority.low,
      actions: [
        SuggestionAction(label: 'Start break', isPrimary: true),
        SuggestionAction(label: 'Remind me later', isPrimary: false),
      ],
    ),
  ];

  List<Suggestion> get _activeSuggestions =>
      _suggestions.where((s) => !_dismissedSuggestions.contains(s.id)).toList();

  void _handleDismiss(int id) {
    setState(() {
      _dismissedSuggestions.add(id);
    });
  }

  List<Color> _getPriorityColors(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return [
          const Color(0xFFFF0000).withOpacity(0.2),
          const Color(0xFFFFA500).withOpacity(0.2),
        ];
      case SuggestionPriority.medium:
        return [
          const Color(0xFFFFB800).withOpacity(0.2),
          const Color(0xFFFFD700).withOpacity(0.2),
        ];
      case SuggestionPriority.low:
        return [
          AppColors.cyan500.withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ];
    }
  }

  Color _getPriorityBorder(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return const Color(0xFFFF0000).withOpacity(0.2);
      case SuggestionPriority.medium:
        return const Color(0xFFFFB800).withOpacity(0.2);
      case SuggestionPriority.low:
        return AppColors.cyan500.withOpacity(0.2);
    }
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

                // Current Context
                _buildCurrentContext(context, isMobile)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Suggestions Feed
                _buildSuggestionsList(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Filter/Settings
                _buildSettingsButton(context, isMobile)
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                )),

                // Info
                _buildInfo(context, isMobile)
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/suggestions'),
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
          'Suggestions',
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
          'Context-aware recommendations from AVA',
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

  Widget _buildCurrentContext(BuildContext context, bool isMobile) {
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
          child: Row(
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
                  color: const Color(0xFF9333EA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 11.0,
                    desktop: 12.0,
                  )),
                ),
                child: Icon(
                  LucideIcons.sun,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: 18.0,
                    tablet: 20.0,
                    desktop: 22.0,
                  ),
                  color: const Color(0xFFC084FC),
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
                      'Current Context',
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
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    _buildContextItem('📍 At home'),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem('⏰ Morning (8:30 AM)'),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem('🌤️ Partly cloudy, 18°C'),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem('📅 2 meetings today'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextItem(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        ),
        color: const Color(0xFFC084FC).withOpacity(0.7),
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, bool isMobile) {
    if (_activeSuggestions.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: Responsive.getResponsiveValue(
              context,
              mobile: 40.0,
              tablet: 50.0,
              desktop: 60.0,
            )),
            Icon(
              LucideIcons.checkCircle,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 60.0,
                tablet: 64.0,
                desktop: 72.0,
              ),
              color: AppColors.cyan400.withOpacity(0.3),
            ),
            SizedBox(height: Responsive.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 18.0,
            )),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 15.0,
                  tablet: 16.0,
                  desktop: 17.0,
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
            Text(
              'No new suggestions right now',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                ),
                color: AppColors.cyan400.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _activeSuggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final suggestion = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildSuggestionCard(context, isMobile, suggestion, index),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    bool isMobile,
    Suggestion suggestion,
    int index,
  ) {
    final colors = _getPriorityColors(suggestion.priority);
    final borderColor = _getPriorityBorder(suggestion.priority);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: borderColor,
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
              // Priority Indicator
              if (suggestion.priority == SuggestionPriority.high)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 2.0,
                      tablet: 2.5,
                      desktop: 3.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF0000),
                          const Color(0xFFFFA500),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 20.0,
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                                    colors: colors,
                                  ),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 10.0,
                                    tablet: 11.0,
                                    desktop: 12.0,
                                  )),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  suggestion.icon,
                                  size: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 22.0,
                                    tablet: 24.0,
                                    desktop: 26.0,
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
                                      suggestion.title,
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
                                    Text(
                                      suggestion.description,
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 13.0,
                                          desktop: 14.0,
                                        ),
                                        color: AppColors.textCyan200.withOpacity(0.6),
                                      ),
                                    ),
                                    SizedBox(height: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 6.0,
                                      tablet: 8.0,
                                      desktop: 10.0,
                                    )),
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.clock,
                                          size: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 12.0,
                                            tablet: 13.0,
                                            desktop: 14.0,
                                          ),
                                          color: AppColors.cyan400.withOpacity(0.5),
                                        ),
                                        SizedBox(width: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 4.0,
                                          tablet: 5.0,
                                          desktop: 6.0,
                                        )),
                                        Text(
                                          suggestion.context,
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _handleDismiss(suggestion.id),
                          child: Container(
                            padding: EdgeInsets.all(Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 7.0,
                              desktop: 8.0,
                            )),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 7.0,
                                desktop: 8.0,
                              )),
                              border: Border.all(
                                color: AppColors.textWhite.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                                tablet: 16.0,
                                desktop: 18.0,
                              ),
                              color: AppColors.cyan400.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Action Buttons
                    if (suggestion.actions != null && suggestion.actions!.isNotEmpty) ...[
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      )),
                      Row(
                        children: suggestion.actions!.map((action) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: suggestion.actions!.indexOf(action) < suggestion.actions!.length - 1
                                    ? Responsive.getResponsiveValue(
                                        context,
                                        mobile: 6.0,
                                        tablet: 8.0,
                                        desktop: 10.0,
                                      )
                                    : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  // Handle action
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 9.0,
                                      tablet: 10.0,
                                      desktop: 11.0,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: action.isPrimary
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.cyan500.withOpacity(0.3),
                                              AppColors.blue500.withOpacity(0.3),
                                            ],
                                          )
                                        : null,
                                    color: action.isPrimary ? null : AppColors.textWhite.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0,
                                    )),
                                    border: Border.all(
                                      color: action.isPrimary
                                          ? AppColors.cyan500.withOpacity(0.5)
                                          : AppColors.textWhite.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      action.label,
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 13.0,
                                          desktop: 14.0,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        color: action.isPrimary
                                            ? AppColors.textCyan300
                                            : AppColors.cyan400.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)), duration: 300.ms)
        .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 200 + (index * 100)), duration: 300.ms);
  }

  Widget _buildSettingsButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () {
        // Navigate to suggestion preferences
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
          color: AppColors.textWhite.withOpacity(0.05),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          )),
          border: Border.all(
            color: AppColors.textWhite.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
              child: Text(
                'Suggestion Preferences',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 13.0,
                    tablet: 14.0,
                    desktop: 15.0,
                  ),
                  fontWeight: FontWeight.w500,
                  color: AppColors.cyan400,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
              child: Icon(
                LucideIcons.chevronRight,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
                color: AppColors.cyan400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isMobile) {
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
      child: Text(
        'Suggestions update automatically based on your context, time, location, and calendar',
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
    );
  }
}
