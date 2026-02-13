import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/l10n/app_strings.dart';
import '../state/auth_controller.dart';
import '../widgets/settings_menu.dart';
import '../widgets/navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  final AuthController controller;

  const ProfileScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    if (widget.controller.currentUser == null) {
      widget.controller.loadCurrentUser();
    }
    widget.controller.loadProfile();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;
    final user = widget.controller.currentUser;
    final profile = widget.controller.currentProfile;

    final stats = [
      {'label': AppStrings.tr(context, 'conversations'), 'value': '${profile?.conversationsCount ?? 0}'},
      {'label': AppStrings.tr(context, 'daysActive'), 'value': '${profile?.daysActive ?? 0}'},
      {'label': AppStrings.tr(context, 'hoursSaved'), 'value': '${profile?.hoursSaved ?? 0}'},
    ];

    final recentActivities = [
      {'action': AppStrings.tr(context, 'startedConversation'), 'time': '2 hours ago'},
      {'action': AppStrings.tr(context, 'updatedProfilePicture'), 'time': '1 day ago'},
      {'action': AppStrings.tr(context, 'joinedPersonalAIBuddy'), 'time': '5 days ago'},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
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
                    // Header with Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.tr(context, 'profile'),
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                        SettingsMenu(controller: widget.controller),
                      ],
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Profile Card (données dynamiques GET /auth/me)
                    _ProfileCard(
                      user: user,
                      profile: profile,
                      isMobile: isMobile,
                      isLoading: widget.controller.isLoading,
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, duration: 500.ms),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Stats Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        mainAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: isMobile ? 1.1 : 1.2,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        return _StatCard(
                          value: stats[index]['value']!,
                          label: stats[index]['label']!,
                          isMobile: isMobile,
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 100 + (index * 50)), duration: 500.ms);
                      },
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Recent Activity
                    Text(
                      AppStrings.tr(context, 'recentActivity'),
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms),
                    SizedBox(height: isMobile ? 12 : 16),
                    ...List.generate(recentActivities.length, (index) {
                      return _ProfileActivityItem(
                        action: recentActivities[index]['action']!,
                        time: recentActivities[index]['time']!,
                        isMobile: isMobile,
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 400 + (index * 100)), duration: 500.ms);
                    }),
                    SizedBox(height: isMobile ? 24 : 32),

                    // AI Features Section
                    Text(
                      AppStrings.tr(context, 'aiFeatures'),
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    )),
                    ..._buildAIFeatures(context, isMobile),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAIFeatures(BuildContext context, bool isMobile) {
    final features = [
      {
        'icon': LucideIcons.brain,
        'label': AppStrings.tr(context, 'learningInsights'),
        'route': '/insights',
        'gradient': [
          const Color(0xFF9333EA).withOpacity(0.2),
          const Color(0xFFEC4899).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFFC084FC),
        'description': AppStrings.tr(context, 'learningInsightsDesc'),
      },
      {
        'icon': LucideIcons.plug,
        'label': AppStrings.tr(context, 'connectedServices'),
        'route': '/services',
        'gradient': [
          const Color(0xFF10B981).withOpacity(0.2),
          AppColors.cyan500.withOpacity(0.2),
        ],
        'iconColor': const Color(0xFF10B981),
        'description': AppStrings.tr(context, 'connectedServicesDesc'),
      },
      {
        'icon': LucideIcons.scale,
        'label': AppStrings.tr(context, 'decisionSupport'),
        'route': '/decisions',
        'gradient': [
          const Color(0xFF6366F1).withOpacity(0.2),
          const Color(0xFF9333EA).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFF818CF8),
        'description': AppStrings.tr(context, 'decisionSupportDesc'),
      },
      {
        'icon': LucideIcons.trophy,
        'label': AppStrings.tr(context, 'goalsGrowth'),
        'route': '/goals',
        'gradient': [
          const Color(0xFFF59E0B).withOpacity(0.2),
          const Color(0xFFEAB308).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFFFCD34D),
        'description': AppStrings.tr(context, 'goalsGrowthDesc'),
      },
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;
      return _AIFeatureCard(
        icon: feature['icon'] as IconData,
        label: feature['label'] as String,
        route: feature['route'] as String,
        gradient: feature['gradient'] as List<Color>,
        iconColor: feature['iconColor'] as Color,
        description: feature['description'] as String,
        isMobile: isMobile,
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 500 + (index * 50)), duration: 500.ms)
          .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 500 + (index * 50)), duration: 500.ms);
    }).toList();
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final dynamic profile;
  final bool isMobile;
  final bool isLoading;

  const _ProfileCard({
    required this.user,
    this.profile,
    required this.isMobile,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Données dynamiques : priorité au profil (GET /auth/me), sinon user (login)
    final userName = profile?.name ?? user?.name ?? '—';
    final userEmail = profile?.email ?? user?.email ?? '—';
    final role = isLoading && profile == null
        ? AppStrings.tr(context, 'loading')
        : (profile?.role ?? '—');
    final initials = userName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.6),
            AppColors.primaryDarker.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              children: [
                // Avatar and Basic Info (photo de profil si avatarUrl, sinon initiales)
                Row(
                  children: [
                    Container(
                      width: Responsive.getResponsiveValue(
                        context,
                        mobile: 80.0,
                        tablet: 88.0,
                        desktop: 96.0,
                      ),
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 80.0,
                        tablet: 88.0,
                        desktop: 96.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: (profile?.avatarUrl ?? '').isEmpty
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.cyan500,
                                  AppColors.blue500,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        )),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (profile?.avatarUrl ?? '').isEmpty
                          ? Center(
                              child: Text(
                                initials.isNotEmpty ? initials : 'JD',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 28.0,
                                    tablet: 30.0,
                                    desktop: 32.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Image.network(
                              profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  initials.isNotEmpty ? initials : 'JD',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 28.0,
                                      tablet: 30.0,
                                      desktop: 32.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: isMobile ? 16 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppStrings.tr(context, 'aiEnthusiast'),
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
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/edit-profile'),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          color: AppColors.cyan500.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppColors.cyan400,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 24),
                // Contact Info
                Column(
                  children: [
                    _ContactInfoItem(
                      icon: Icons.mail_outline,
                      text: userEmail,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    _ContactInfoItem(
                      icon: Icons.calendar_today,
                      text: profile?.joinedLabel.isNotEmpty == true
                          ? profile!.joinedLabel
                          : '—',
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    _ContactInfoItem(
                      icon: Icons.location_on,
                      text: profile?.location ?? '—',
                      isMobile: isMobile,
                    ),
                    if ((profile?.phone ?? '').isNotEmpty) ...[
                      SizedBox(height: isMobile ? 12 : 16),
                      _ContactInfoItem(
                        icon: Icons.phone_outlined,
                        text: profile!.phone!,
                        isMobile: isMobile,
                      ),
                    ],
                    if ((profile?.birthDate ?? '').isNotEmpty) ...[
                      SizedBox(height: isMobile ? 12 : 16),
                      _ContactInfoItem(
                        icon: Icons.calendar_today_outlined,
                        text: profile!.birthDate!,
                        isMobile: isMobile,
                      ),
                    ],
                    if ((profile?.bio ?? '').isNotEmpty) ...[
                      SizedBox(height: isMobile ? 12 : 16),
                      _ContactInfoItem(
                        icon: Icons.info_outline,
                        text: profile!.bio!,
                        isMobile: isMobile,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMobile;

  const _ContactInfoItem({
    required this.icon,
    required this.text,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: isMobile ? 16 : 18,
          color: AppColors.cyan400,
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: AppColors.textCyan200.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isMobile;

  const _StatCard({
    required this.value,
    required this.label,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan400,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: AppColors.textCyan200.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileActivityItem extends StatelessWidget {
  final String action;
  final String time;
  final bool isMobile;

  const _ProfileActivityItem({
    required this.action,
    required this.time,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textWhite,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: AppColors.textCyan200.withOpacity(0.5),
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

class _AIFeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final List<Color> gradient;
  final Color iconColor;
  final String description;
  final bool isMobile;

  const _AIFeatureCard({
    required this.icon,
    required this.label,
    required this.route,
    required this.gradient,
    required this.iconColor,
    required this.description,
    required this.isMobile,
  });

  @override
  State<_AIFeatureCard> createState() => _AIFeatureCardState();
}

class _AIFeatureCardState extends State<_AIFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(widget.route),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          margin: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
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
              color: _isHovered
                  ? AppColors.cyan500.withOpacity(0.3)
                  : AppColors.cyan500.withOpacity(0.1),
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
            child: Stack(
              children: [
                // Hover glow effect
                if (_isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: [
                            AppColors.cyan400.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: EdgeInsets.all(Responsive.getResponsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 16.0,
                      desktop: 20.0,
                    )),
                    child: Row(
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
                              colors: widget.gradient,
                            ),
                            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                              context,
                              mobile: 10.0,
                              tablet: 11.0,
                              desktop: 12.0,
                            )),
                            border: Border.all(
                              color: AppColors.cyan500.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            size: Responsive.getResponsiveValue(
                              context,
                              mobile: 22.0,
                              tablet: 24.0,
                              desktop: 26.0,
                            ),
                            color: widget.iconColor,
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
                                widget.label,
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
                                desktop: 5.0,
                              )),
                              Text(
                                widget.description,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  color: AppColors.textCyan200.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 18.0,
                            tablet: 20.0,
                            desktop: 22.0,
                          ),
                          color: AppColors.cyan400,
                        ),
                      ],
                    ),
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
