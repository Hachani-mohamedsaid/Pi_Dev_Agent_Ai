import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum NotificationPriority { critical, important, canWait }
enum NotificationCategory { all, work, personal, travel }

class Notification {
  final int id;
  final String title;
  final String message;
  final NotificationPriority priority;
  final NotificationCategory category;
  final String time;
  final String? action;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.category,
    required this.time,
    this.action,
  });
}

class NotificationsCenterPage extends StatefulWidget {
  const NotificationsCenterPage({super.key});

  @override
  State<NotificationsCenterPage> createState() => _NotificationsCenterPageState();
}

class _NotificationsCenterPageState extends State<NotificationsCenterPage> {
  NotificationCategory _filter = NotificationCategory.all;
  final List<int> _dismissedIds = [];

  final List<Notification> _notifications = [
    Notification(
      id: 1,
      title: 'Meeting in 15 minutes',
      message: 'Team standup - Conference Room A',
      priority: NotificationPriority.critical,
      category: NotificationCategory.work,
      time: '2 min ago',
      action: 'View details',
    ),
    Notification(
      id: 2,
      title: 'Email requires response',
      message: 'Sarah asked about Q1 report deadline',
      priority: NotificationPriority.important,
      category: NotificationCategory.work,
      time: '10 min ago',
      action: 'Reply now',
    ),
    Notification(
      id: 3,
      title: 'Traffic alert',
      message: 'Heavy traffic on your route home',
      priority: NotificationPriority.important,
      category: NotificationCategory.travel,
      time: '30 min ago',
      action: 'View route',
    ),
    Notification(
      id: 4,
      title: 'Lunch break suggested',
      message: "You've been working for 4 hours",
      priority: NotificationPriority.canWait,
      category: NotificationCategory.personal,
      time: '1 hour ago',
    ),
    Notification(
      id: 5,
      title: 'Weekly summary ready',
      message: 'Your productivity insights are available',
      priority: NotificationPriority.canWait,
      category: NotificationCategory.work,
      time: '2 hours ago',
    ),
  ];

  List<Notification> get _activeNotifications =>
      _notifications.where((n) => !_dismissedIds.contains(n.id)).toList();

  List<Notification> get _filteredNotifications {
    if (_filter == NotificationCategory.all) {
      return _activeNotifications;
    }
    return _activeNotifications.where((n) => n.category == _filter).toList();
  }

  void _handleDismiss(int id) {
    setState(() {
      _dismissedIds.add(id);
    });
  }

  Map<String, dynamic> _getPriorityConfig(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return {
          'bg': [const Color(0xFFFF0000).withOpacity(0.2), const Color(0xFFFFA500).withOpacity(0.2)],
          'border': const Color(0xFFFF0000).withOpacity(0.3),
          'icon': LucideIcons.alertCircle,
          'iconColor': const Color(0xFFFF6B6B),
          'label': 'Critical',
        };
      case NotificationPriority.important:
        return {
          'bg': [const Color(0xFFFFB800).withOpacity(0.2), const Color(0xFFFFD700).withOpacity(0.2)],
          'border': const Color(0xFFFFB800).withOpacity(0.3),
          'icon': LucideIcons.bell,
          'iconColor': const Color(0xFFFFD93D),
          'label': 'Important',
        };
      case NotificationPriority.canWait:
        return {
          'bg': [AppColors.cyan500.withOpacity(0.2), AppColors.blue500.withOpacity(0.2)],
          'border': AppColors.cyan500.withOpacity(0.3),
          'icon': LucideIcons.clock,
          'iconColor': AppColors.cyan400,
          'label': 'Can wait',
        };
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
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                )),

                // Filter
                _buildFilter(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Notifications List
                _buildNotificationsList(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Settings Button
                _buildSettingsButton(context, isMobile)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                )),

                // Info
                _buildInfo(context, isMobile)
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/notifications-center'),
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
              'Notifications',
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
            if (_activeNotifications.isNotEmpty)
              Container(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: 28.0,
                  tablet: 32.0,
                  desktop: 36.0,
                ),
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 28.0,
                  tablet: 32.0,
                  desktop: 36.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF0000).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_activeNotifications.length}',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
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
        Text(
          'AI-filtered and prioritized',
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

  Widget _buildFilter(BuildContext context, bool isMobile) {
    final categories = [
      {'id': NotificationCategory.all, 'label': 'All'},
      {'id': NotificationCategory.work, 'label': 'Work'},
      {'id': NotificationCategory.personal, 'label': 'Personal'},
      {'id': NotificationCategory.travel, 'label': 'Travel'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _filter == cat['id'] as NotificationCategory;
          return Padding(
            padding: EdgeInsets.only(
              right: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            child: GestureDetector(
              onTap: () => setState(() => _filter = cat['id'] as NotificationCategory),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                  vertical: Responsive.getResponsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 9.0,
                    desktop: 10.0,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.cyan500.withOpacity(0.3),
                            AppColors.blue500.withOpacity(0.3),
                          ],
                        )
                      : null,
                  color: isSelected ? null : AppColors.textWhite.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  )),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.cyan500.withOpacity(0.5)
                        : AppColors.textWhite.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.textCyan300
                        : AppColors.cyan400.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, bool isMobile) {
    if (_filteredNotifications.isEmpty) {
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
              LucideIcons.check,
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
              'No notifications in this category',
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
      children: _filteredNotifications.asMap().entries.map((entry) {
        final index = entry.key;
        final notif = entry.value;
        final config = _getPriorityConfig(notif.priority);

        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildNotificationCard(context, isMobile, notif, config, index),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    bool isMobile,
    Notification notif,
    Map<String, dynamic> config,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config['bg'] as List<Color>,
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: config['border'] as Color,
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
              // Priority bar for critical
              if (notif.priority == NotificationPriority.critical)
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
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        )),
                        topRight: Radius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        )),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: config['bg'] as List<Color>,
                        ),
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 11.0,
                          desktop: 12.0,
                        )),
                        border: Border.all(
                          color: config['border'] as Color,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        config['icon'] as IconData,
                        color: config['iconColor'] as Color,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
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
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 13.0,
                                      tablet: 14.0,
                                      desktop: 15.0,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _handleDismiss(notif.id),
                                child: Container(
                                  padding: EdgeInsets.all(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 4.0,
                                    tablet: 5.0,
                                    desktop: 6.0,
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
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 4.0,
                            tablet: 5.0,
                            desktop: 6.0,
                          )),
                          Text(
                            notif.message,
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
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          )),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                    color: config['iconColor'] as Color,
                                  ),
                                  SizedBox(width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 4.0,
                                    tablet: 5.0,
                                    desktop: 6.0,
                                  )),
                                  Text(
                                    notif.time,
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
                              if (notif.action != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 12.0,
                                      desktop: 14.0,
                                    ),
                                    vertical: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 5.0,
                                      tablet: 6.0,
                                      desktop: 7.0,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: notif.priority == NotificationPriority.critical
                                        ? const Color(0xFFFF0000).withOpacity(0.3)
                                        : AppColors.cyan500.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                      context,
                                      mobile: 6.0,
                                      tablet: 7.0,
                                      desktop: 8.0,
                                    )),
                                    border: Border.all(
                                      color: notif.priority == NotificationPriority.critical
                                          ? const Color(0xFFFF0000).withOpacity(0.4)
                                          : AppColors.cyan500.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    notif.action!,
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 10.0,
                                        tablet: 11.0,
                                        desktop: 12.0,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      color: notif.priority == NotificationPriority.critical
                                          ? const Color(0xFFFFB3B3)
                                          : AppColors.cyan400,
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
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + (index * 50)), duration: 300.ms)
        .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 50)), duration: 300.ms);
  }

  Widget _buildSettingsButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () {
        // Navigate to notification preferences
        context.push('/notifications');
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.filter,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
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
              'Notification Preferences',
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
        'AVA automatically filters and prioritizes notifications based on your context and preferences',
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
