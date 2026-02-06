import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Map<String, bool> _notifications = {
    'push': true,
    'messages': true,
    'email': false,
    'reminders': true,
    'updates': true,
    'sounds': false,
  };

  bool _doNotDisturbScheduled = false;
  String _doNotDisturbFrom = '22:00';
  String _doNotDisturbTo = '08:00';

  void _handleToggle(String id) {
    setState(() {
      _notifications[id] = !(_notifications[id] ?? false);
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

    final notificationSettings = [
      {
        'id': 'push',
        'title': 'Push Notifications',
        'description': 'Receive push notifications on your device',
        'icon': LucideIcons.bell,
      },
      {
        'id': 'messages',
        'title': 'Message Alerts',
        'description': 'Get notified when you receive new messages',
        'icon': LucideIcons.messageSquare,
      },
      {
        'id': 'email',
        'title': 'Email Notifications',
        'description': 'Receive updates and newsletters via email',
        'icon': LucideIcons.mail,
      },
      {
        'id': 'reminders',
        'title': 'Reminders',
        'description': 'Get reminders for scheduled tasks',
        'icon': LucideIcons.calendar,
      },
      {
        'id': 'updates',
        'title': 'App Updates',
        'description': 'Notifications about new features and updates',
        'icon': LucideIcons.trendingUp,
      },
      {
        'id': 'sounds',
        'title': 'Notification Sounds',
        'description': 'Play sounds for notifications',
        'icon': LucideIcons.volume2,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: padding,
              bottom: padding + MediaQuery.of(context).padding.bottom + Responsive.getResponsiveValue(
                context,
                mobile: 20.0,
                tablet: 24.0,
                desktop: 32.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, isMobile, padding)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                )),

                // Header Info
                _buildHeaderInfo(context, isMobile)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 32.0,
                )),

                // Notification Settings
                ...notificationSettings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final setting = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 16.0,
                      ),
                    ),
                    child: _buildNotificationItem(
                      context,
                      isMobile,
                      setting['icon'] as IconData,
                      setting['title'] as String,
                      setting['description'] as String,
                      _notifications[setting['id'] as String] ?? false,
                      () => _handleToggle(setting['id'] as String),
                      index,
                    ),
                  );
                }),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 32.0,
                )),

                // Do Not Disturb Section
                _buildDoNotDisturbSection(context, isMobile)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, double padding) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(
              context,
              mobile: 8.0,
              tablet: 9.0,
              desktop: 10.0,
            )),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1e4a66).withOpacity(0.6),
                  const Color(0xFF16384d).withOpacity(0.6),
                ],
              ),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 13.0,
                desktop: 14.0,
              )),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.cyan400,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: 18.0,
                    tablet: 20.0,
                    desktop: 22.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          'Notifications',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 18.0,
              tablet: 20.0,
              desktop: 22.0,
            ),
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(width: Responsive.getResponsiveValue(
          context,
          mobile: 36.0,
          tablet: 40.0,
          desktop: 44.0,
        )),
      ],
    );
  }

  Widget _buildHeaderInfo(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 14.0,
        tablet: 16.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan500.withOpacity(0.1),
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
          color: AppColors.cyan500.withOpacity(0.2),
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
            children: [
              Icon(
                LucideIcons.bell,
                color: AppColors.cyan400,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
              ),
              SizedBox(width: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              )),
              Expanded(
                child: Text(
                  'Manage how you receive notifications',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    bool isMobile,
    IconData icon,
    String title,
    String description,
    bool enabled,
    VoidCallback onToggle,
    int index,
  ) {
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
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                )),
                decoration: BoxDecoration(
                  gradient: enabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.cyan500.withOpacity(0.2),
                            AppColors.blue500.withOpacity(0.2),
                          ],
                        )
                      : null,
                  color: enabled ? null : AppColors.cyan500.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 11.0,
                    desktop: 12.0,
                  )),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.cyan400 : AppColors.cyan400.withOpacity(0.5),
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
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 4.0,
                    )),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        color: AppColors.textCyan200.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.cyan500,
                activeTrackColor: AppColors.blue500,
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

  Widget _buildDoNotDisturbSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            ),
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: Text(
            'Do Not Disturb',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
        ),
        Container(
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheduled',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 15.0,
                            desktop: 16.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWhite,
                        ),
                      ),
                      Switch(
                        value: _doNotDisturbScheduled,
                        onChanged: (value) => setState(() => _doNotDisturbScheduled = value),
                        activeColor: AppColors.cyan500,
                        activeTrackColor: AppColors.blue500,
                      ),
                    ],
                  ),
                  if (_doNotDisturbScheduled) ...[
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 16.0,
                    )),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 10.0,
                                    tablet: 11.0,
                                    desktop: 12.0,
                                  ),
                                  color: AppColors.textCyan200.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              )),
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
                                    mobile: 8.0,
                                    tablet: 9.0,
                                    desktop: 10.0,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0f2940).withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 8.0,
                                    tablet: 9.0,
                                    desktop: 10.0,
                                  )),
                                  border: Border.all(
                                    color: AppColors.cyan500.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _doNotDisturbFrom,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0,
                                    ),
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 16.0,
                        )),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 10.0,
                                    tablet: 11.0,
                                    desktop: 12.0,
                                  ),
                                  color: AppColors.textCyan200.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              )),
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
                                    mobile: 8.0,
                                    tablet: 9.0,
                                    desktop: 10.0,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0f2940).withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 8.0,
                                    tablet: 9.0,
                                    desktop: 10.0,
                                  )),
                                  border: Border.all(
                                    color: AppColors.cyan500.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _doNotDisturbTo,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0,
                                    ),
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
