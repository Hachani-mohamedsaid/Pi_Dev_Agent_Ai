import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _marketingEmails = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _quietHoursEnabled = false;
  bool _lockScreenNotifications = true;
  bool _notificationBadges = true;
  bool _notificationPreview = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: padding,
              bottom: padding + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryLight.withOpacity(0.6),
                              AppColors.primaryDarker.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.cyan400,
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(width: isMobile ? 40 : 48),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 16 : 20),

                // Header Info
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan500.withOpacity(0.1),
                        AppColors.blue500.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    border: Border.all(
                      color: AppColors.cyan500.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: AppColors.cyan400,
                            size: isMobile ? 20 : 24,
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Manage your notification preferences',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: AppColors.textCyan200.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Notification Settings
                _NotificationSection(
                  title: 'Notification Types',
                  isMobile: isMobile,
                  children: [
                    _NotificationItem(
                      icon: Icons.notifications_active,
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications on your device',
                      value: _pushNotifications,
                      onChanged: (value) => setState(() => _pushNotifications = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.email,
                      title: 'Email Notifications',
                      subtitle: 'Receive notifications via email',
                      value: _emailNotifications,
                      onChanged: (value) => setState(() => _emailNotifications = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.sms,
                      title: 'SMS Notifications',
                      subtitle: 'Receive notifications via SMS',
                      value: _smsNotifications,
                      onChanged: (value) => setState(() => _smsNotifications = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.campaign,
                      title: 'Marketing Emails',
                      subtitle: 'Receive promotional emails',
                      value: _marketingEmails,
                      onChanged: (value) => setState(() => _marketingEmails = value),
                      isMobile: isMobile,
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 24 : 32),

                // Notification Preferences
                _NotificationSection(
                  title: 'Preferences',
                  isMobile: isMobile,
                  children: [
                    _NotificationItem(
                      icon: Icons.volume_up,
                      title: 'Sound',
                      subtitle: 'Play sound for notifications',
                      value: _soundEnabled,
                      onChanged: (value) => setState(() => _soundEnabled = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.vibration,
                      title: 'Vibration',
                      subtitle: 'Vibrate for notifications',
                      value: _vibrationEnabled,
                      onChanged: (value) => setState(() => _vibrationEnabled = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.badge,
                      title: 'Notification Badges',
                      subtitle: 'Show badge counts on app icon',
                      value: _notificationBadges,
                      onChanged: (value) => setState(() => _notificationBadges = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.preview,
                      title: 'Notification Preview',
                      subtitle: 'Show preview of notifications',
                      value: _notificationPreview,
                      onChanged: (value) => setState(() => _notificationPreview = value),
                      isMobile: isMobile,
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 24 : 32),

                // Advanced Settings
                _NotificationSection(
                  title: 'Advanced Settings',
                  isMobile: isMobile,
                  children: [
                    _NotificationItem(
                      icon: Icons.lock,
                      title: 'Lock Screen Notifications',
                      subtitle: 'Show notifications on lock screen',
                      value: _lockScreenNotifications,
                      onChanged: (value) => setState(() => _lockScreenNotifications = value),
                      isMobile: isMobile,
                    ),
                    _NotificationItem(
                      icon: Icons.bedtime,
                      title: 'Quiet Hours',
                      subtitle: 'Silence notifications during set hours',
                      value: _quietHoursEnabled,
                      onChanged: (value) => setState(() => _quietHoursEnabled = value),
                      isMobile: isMobile,
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 24 : 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isMobile;

  const _NotificationSection({
    required this.title,
    required this.children,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isMobile ? 8 : 12, bottom: isMobile ? 12 : 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isMobile;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan500.withOpacity(0.2),
                      AppColors.blue500.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.cyan400,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: AppColors.textCyan200.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.cyan500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
