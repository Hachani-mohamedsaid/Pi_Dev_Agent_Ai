import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum ViewMode { day, week }
enum InsightType { conflict, lowEnergy, optimization }

class Event {
  final int id;
  final String title;
  final String time;
  final String duration;
  final EventInsight? aiInsight;

  Event({
    required this.id,
    required this.title,
    required this.time,
    required this.duration,
    this.aiInsight,
  });
}

class EventInsight {
  final InsightType type;
  final String message;

  EventInsight({
    required this.type,
    required this.message,
  });
}

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  ViewMode _viewMode = ViewMode.day;
  Event? _selectedEvent;

  final List<Event> _events = [
    Event(
      id: 1,
      title: 'Team Standup',
      time: '09:00',
      duration: '30 min',
    ),
    Event(
      id: 2,
      title: 'Client Meeting',
      time: '10:00',
      duration: '1 hour',
      aiInsight: EventInsight(
        type: InsightType.lowEnergy,
        message: 'This meeting is scheduled during a period when you are usually less focused.',
      ),
    ),
    Event(
      id: 3,
      title: 'Project Review',
      time: '14:00',
      duration: '45 min',
      aiInsight: EventInsight(
        type: InsightType.conflict,
        message: 'Time conflict detected with another commitment.',
      ),
    ),
    Event(
      id: 4,
      title: 'Design Discussion',
      time: '16:00',
      duration: '1 hour',
      aiInsight: EventInsight(
        type: InsightType.optimization,
        message: 'Optimization opportunity: This could be combined with tomorrow\'s design sync.',
      ),
    ),
  ];

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.conflict:
        return const Color(0xFFFF6B6B);
      case InsightType.lowEnergy:
        return const Color(0xFFFFD93D);
      case InsightType.optimization:
        return AppColors.cyan400;
    }
  }

  Color _getInsightBgColor(InsightType type) {
    switch (type) {
      case InsightType.conflict:
        return const Color(0xFFFF0000).withOpacity(0.1);
      case InsightType.lowEnergy:
        return const Color(0xFFFFB800).withOpacity(0.1);
      case InsightType.optimization:
        return AppColors.cyan500.withOpacity(0.1);
    }
  }

  Color _getInsightBorderColor(InsightType type) {
    switch (type) {
      case InsightType.conflict:
        return const Color(0xFFFF0000).withOpacity(0.2);
      case InsightType.lowEnergy:
        return const Color(0xFFFFB800).withOpacity(0.2);
      case InsightType.optimization:
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
                      mobile: 14.0,
                      tablet: 16.0,
                      desktop: 18.0,
                    )),

                    // View Mode Toggle
                    _buildViewModeToggle(context, isMobile),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 24.0,
                      desktop: 28.0,
                    )),

                    // Calendar View
                    _buildEventsList(context, isMobile),
                  ],
                ),
              ),
              // Event Detail Modal
              if (_selectedEvent != null)
                _buildEventDetailModal(context, isMobile),
              
              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/agenda'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Agenda',
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
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Previous day/week
                  },
                  child: Container(
                    padding: EdgeInsets.all(Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 9.0,
                      desktop: 10.0,
                    )),
                    decoration: BoxDecoration(
                      color: AppColors.cyan500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      )),
                      border: Border.all(
                        color: AppColors.cyan500.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
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
                GestureDetector(
                  onTap: () {
                    // Next day/week
                  },
                  child: Container(
                    padding: EdgeInsets.all(Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 9.0,
                      desktop: 10.0,
                    )),
                    decoration: BoxDecoration(
                      color: AppColors.cyan500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      )),
                      border: Border.all(
                        color: AppColors.cyan500.withOpacity(0.2),
                        width: 1,
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
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewModeToggle(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 3.0,
        tablet: 4.0,
        desktop: 5.0,
      )),
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
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _viewMode = ViewMode.day),
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
                      color: _viewMode == ViewMode.day
                          ? AppColors.cyan500.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      )),
                      border: _viewMode == ViewMode.day
                          ? Border.all(
                              color: AppColors.cyan500.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Day',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: _viewMode == ViewMode.day
                              ? AppColors.textCyan300
                              : AppColors.cyan400.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _viewMode = ViewMode.week),
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
                      color: _viewMode == ViewMode.week
                          ? AppColors.cyan500.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      )),
                      border: _viewMode == ViewMode.week
                          ? Border.all(
                              color: AppColors.cyan500.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Week',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: _viewMode == ViewMode.week
                              ? AppColors.textCyan300
                              : AppColors.cyan400.withOpacity(0.6),
                        ),
                      ),
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

  Widget _buildEventsList(BuildContext context, bool isMobile) {
    return Column(
      children: _events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildEventCard(context, isMobile, event, index),
        );
      }).toList(),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    bool isMobile,
    Event event,
    int index,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedEvent = event),
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
                // Event Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
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
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 4.0,
                            tablet: 5.0,
                            desktop: 6.0,
                          )),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 13.0,
                                  tablet: 14.0,
                                  desktop: 15.0,
                                ),
                                color: AppColors.cyan400.withOpacity(0.7),
                              ),
                              SizedBox(width: Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              )),
                              Text(
                                '${event.time} • ${event.duration}',
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.calendar,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
                      ),
                      color: AppColors.cyan400.withOpacity(0.5),
                    ),
                  ],
                ),
                // AI Insight
                if (event.aiInsight != null) ...[
                  SizedBox(height: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  )),
                  Container(
                    padding: EdgeInsets.all(Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    )),
                    decoration: BoxDecoration(
                      color: _getInsightBgColor(event.aiInsight!.type),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      )),
                      border: Border.all(
                        color: _getInsightBorderColor(event.aiInsight!.type),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.brain,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 18.0,
                          ),
                          color: _getInsightColor(event.aiInsight!.type),
                        ),
                        SizedBox(width: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        )),
                        Expanded(
                          child: Text(
                            event.aiInsight!.message,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 11.0,
                                tablet: 12.0,
                                desktop: 13.0,
                              ),
                              color: _getInsightColor(event.aiInsight!.type),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100), duration: 300.ms)
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 100), duration: 300.ms);
  }

  Widget _buildEventDetailModal(BuildContext context, bool isMobile) {
    if (_selectedEvent == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _selectedEvent = null),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping modal content
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 22.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a3a52),
                      Color(0xFF0f2940),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    )),
                    topRight: Radius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    )),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.cyan500.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    Text(
                      _selectedEvent!.title,
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
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    )),
                    Text(
                      '${_selectedEvent!.time} • ${_selectedEvent!.duration}',
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
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 16.0,
                      desktop: 18.0,
                    )),
                    // AI Insight
                    if (_selectedEvent!.aiInsight != null) ...[
                      Container(
                        padding: EdgeInsets.all(Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 20.0,
                        )),
                        decoration: BoxDecoration(
                          color: _getInsightBgColor(_selectedEvent!.aiInsight!.type),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          )),
                          border: Border.all(
                            color: _getInsightBorderColor(_selectedEvent!.aiInsight!.type),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.brain,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              color: _getInsightColor(_selectedEvent!.aiInsight!.type),
                            ),
                            SizedBox(width: Responsive.getResponsiveValue(
                              context,
                              mobile: 10.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            )),
                            Expanded(
                              child: Text(
                                _selectedEvent!.aiInsight!.message,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 13.0,
                                    desktop: 14.0,
                                  ),
                                  color: _getInsightColor(_selectedEvent!.aiInsight!.type),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      )),
                    ],
                    // Actions
                    Column(
                      children: [
                        _buildActionButton(
                          context,
                          isMobile,
                          'Keep as is',
                          false,
                          false,
                        ),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        )),
                        _buildActionButton(
                          context,
                          isMobile,
                          'Reschedule',
                          true,
                          false,
                        ),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        )),
                        _buildActionButton(
                          context,
                          isMobile,
                          'Ask for suggestion',
                          false,
                          true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isMobile,
    String label,
    bool isPrimary,
    bool isSecondary,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle action
        if (label == 'Keep as is') {
          setState(() => _selectedEvent = null);
        }
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
          color: isPrimary
              ? AppColors.cyan500.withOpacity(0.2)
              : AppColors.textWhite.withOpacity(0.05),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          )),
          border: Border.all(
            color: isPrimary
                ? AppColors.cyan500.withOpacity(0.3)
                : AppColors.textWhite.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
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
              color: isPrimary
                  ? AppColors.textCyan300
                  : isSecondary
                      ? AppColors.cyan400.withOpacity(0.7)
                      : AppColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}
