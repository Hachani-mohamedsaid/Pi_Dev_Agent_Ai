import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

class ConnectedServicesPage extends StatelessWidget {
  const ConnectedServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final services = [
      {
        'name': 'Google Calendar',
        'emoji': '📅',
        'description': 'Schedule management and optimization',
        'status': 'connected',
        'lastSync': '5 min ago',
        'permissions': ['Read events', 'Create events', 'Update events'],
        'usage': 156,
      },
      {
        'name': 'Gmail',
        'emoji': '📧',
        'description': 'Email summarization and drafting',
        'status': 'connected',
        'lastSync': '10 min ago',
        'permissions': ['Read emails', 'Send emails', 'Draft emails'],
        'usage': 89,
      },
      {
        'name': 'Uber',
        'emoji': '🚗',
        'description': 'Quick ride booking',
        'status': 'connected',
        'lastSync': '1 hour ago',
        'permissions': ['Book rides', 'View history'],
        'usage': 12,
      },
      {
        'name': 'Slack',
        'emoji': '💬',
        'description': 'Team communication',
        'status': 'available',
        'permissions': ['Read messages', 'Send messages'],
      },
      {
        'name': 'Spotify',
        'emoji': '🎵',
        'description': 'Music for focus sessions',
        'status': 'available',
        'permissions': ['Control playback', 'View playlists'],
      },
      {
        'name': 'Food Delivery',
        'emoji': '🍕',
        'description': 'Order your favorite meals',
        'status': 'available',
        'permissions': ['Place orders', 'View history'],
      },
      {
        'name': 'Notion',
        'emoji': '📝',
        'description': 'Note-taking and task management',
        'status': 'available',
        'permissions': ['Read pages', 'Create pages'],
      },
      {
        'name': 'GitHub',
        'emoji': '💻',
        'description': 'Code repository management',
        'status': 'available',
        'permissions': ['Read repos', 'Create issues'],
      },
    ];

    final connectedServices = services.where((s) => s['status'] == 'connected').toList();
    final availableServices = services.where((s) => s['status'] == 'available').toList();
    final totalActions = connectedServices.fold<int>(
      0,
      (sum, s) => sum + (s['usage'] as int? ?? 0),
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

                // Stats
                _buildStats(context, isMobile, connectedServices.length, totalActions)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Connected Services
                Text(
                  'Connected',
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
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),
                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                )),
                ...connectedServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      ),
                    ),
                    child: _buildConnectedServiceCard(context, isMobile, service)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 300 + (index * 100)), duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 300 + (index * 100)), duration: 300.ms),
                  );
                }),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0,
                )),

                // Available Services
                Text(
                  'Available to Connect',
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
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 300.ms),
                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                )),
                ...availableServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      ),
                    ),
                    child: _buildAvailableServiceCard(context, isMobile, service)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 600 + (index * 100)), duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 600 + (index * 100)), duration: 300.ms),
                  );
                }),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Info Footer
                _buildInfoFooter(context, isMobile)
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/services'),
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
          'Connected Services',
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
          'Manage your integrations',
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

  Widget _buildStats(BuildContext context, bool isMobile, int connectedCount, int totalActions) {
    return Row(
      children: [
        Expanded(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.checkCircle,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
                      ),
                      color: const Color(0xFF10B981),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    Text(
                      '$connectedCount',
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
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    Text(
                      'Connected',
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
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms),
        ),
        SizedBox(width: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        Expanded(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
                      ),
                      color: AppColors.cyan400,
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    Text(
                      '$totalActions',
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
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    Text(
                      'Total actions',
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
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 200.ms, duration: 300.ms),
        ),
      ],
    );
  }

  Widget _buildConnectedServiceCard(BuildContext context, bool isMobile, Map<String, dynamic> service) {
    final permissions = service['permissions'] as List<String>? ?? [];
    final usage = service['usage'] as int?;

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
          child: Column(
            children: [
              Row(
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
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.2),
                          AppColors.cyan500.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 11.0,
                        desktop: 12.0,
                      )),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        service['emoji'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 22.0,
                            tablet: 24.0,
                            desktop: 26.0,
                          ),
                        ),
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
                          children: [
                            Expanded(
                              child: Text(
                                service['name'] as String,
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
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 5.0,
                                      tablet: 6.0,
                                      desktop: 7.0,
                                    ),
                                    height: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 5.0,
                                      tablet: 6.0,
                                      desktop: 7.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 3.0,
                                    tablet: 4.0,
                                    desktop: 5.0,
                                  )),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 10.0,
                                        tablet: 11.0,
                                        desktop: 12.0,
                                      ),
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
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
                          service['description'] as String,
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
                        if (service['lastSync'] != null) ...[
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 8.0,
                            desktop: 10.0,
                          )),
                          Text(
                            'Last sync: ${service['lastSync']}',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 11.0,
                                tablet: 12.0,
                                desktop: 13.0,
                              ),
                              color: AppColors.cyan400.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
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
                      // Handle settings
                    },
                    child: Container(
                      padding: EdgeInsets.all(Responsive.getResponsiveValue(
                        context,
                        mobile: 7.0,
                        tablet: 8.0,
                        desktop: 9.0,
                      )),
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.1),
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
                      child: Icon(
                        LucideIcons.settings,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        color: AppColors.cyan400,
                      ),
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
              // Permissions & Usage
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      ),
                      runSpacing: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      ),
                      children: [
                        ...permissions.take(2).map((perm) {
                          return Container(
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
                              color: AppColors.cyan500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              )),
                              border: Border.all(
                                color: AppColors.cyan500.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              perm,
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
                        }),
                        if (permissions.length > 2)
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
                              color: AppColors.cyan500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              )),
                              border: Border.all(
                                color: AppColors.cyan500.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '+${permissions.length - 2}',
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
                          ),
                      ],
                    ),
                    if (usage != null)
                      Text(
                        '$usage actions',
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
    );
  }

  Widget _buildAvailableServiceCard(BuildContext context, bool isMobile, Map<String, dynamic> service) {
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
            const Color(0xFF1e4a66).withOpacity(0.2),
            const Color(0xFF16384d).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.05),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                      color: AppColors.cyan500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      )),
                      border: Border.all(
                        color: AppColors.cyan500.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        service['emoji'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] as String,
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
                        service['description'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: AppColors.cyan400.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Handle connect
                },
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
                      mobile: 7.0,
                      tablet: 8.0,
                      desktop: 9.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cyan500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 9.0,
                      desktop: 10.0,
                    )),
                    border: Border.all(
                      color: AppColors.cyan500.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      fontWeight: FontWeight.w500,
                      color: AppColors.cyan400,
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

  Widget _buildInfoFooter(BuildContext context, bool isMobile) {
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
        'All connections are encrypted and can be removed at any time. You control what data AVA can access.',
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
