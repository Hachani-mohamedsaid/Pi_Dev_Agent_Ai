import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'package:pi_dev_agentia/generated/l10n.dart';
import '../state/auth_controller.dart';
import '../widgets/settings_menu.dart';
import '../widgets/navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  final AuthController controller;

  const ProfileScreen({super.key, required this.controller});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = isMobile ? 24.0 : 32.0;
    final user = widget.controller.currentUser;
    final profile = widget.controller.currentProfile;
    final titleColor = isDark ? AppColors.textWhite : const Color(0xFF11263A);
    final panelGradient = isDark
        ? AppColors.primaryGradient
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFF), Color(0xFFE7F2FA), Color(0xFFF7FBFF)],
          );

    final stats = [
      {
        'label': S.of(context).conversations,
        'value': '${profile?.conversationsCount ?? 0}',
      },
      {
        'label': S.of(context).daysActive,
        'value': '${profile?.daysActive ?? 0}',
      },
      {
        'label': S.of(context).hoursSaved,
        'value': '${profile?.hoursSaved ?? 0}',
      },
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: panelGradient),
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
                          S.of(context).profile,
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
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

                    // Stats row (compact)
                    SizedBox(
                      height: 80,
                      child: Row(
                        children: List.generate(stats.length, (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < stats.length - 1
                                    ? (isMobile ? 10.0 : 12.0)
                                    : 0,
                              ),
                              child:
                                  _StatCard(
                                    value: stats[index]['value']!,
                                    label: stats[index]['label']!,
                                    isMobile: isMobile,
                                  ).animate().fadeIn(
                                    delay: Duration(
                                      milliseconds: 100 + (index * 50),
                                    ),
                                    duration: 500.ms,
                                  ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // AI Features Section
                    Text(
                      S.of(context).aiFeatures, // TODO: Ajouter dans ARB
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                    ..._buildAIFeatures(context, isMobile),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 24.0,
                        tablet: 28.0,
                        desktop: 32.0,
                      ),
                    ),
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
        'label': S.of(context).learningInsights, // TODO: Ajouter dans ARB
        'route': '/insights',
        'gradient': [
          const Color(0xFF9333EA).withOpacity(0.2),
          const Color(0xFFEC4899).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFFC084FC),
        'description': S
            .of(context)
            .learningInsightsDesc, // TODO: Ajouter dans ARB
      },
      {
        'icon': LucideIcons.plug,
        'label': S.of(context).connectedServices, // TODO: Ajouter dans ARB
        'route': '/services',
        'gradient': [
          const Color(0xFF10B981).withOpacity(0.2),
          AppColors.cyan500.withOpacity(0.2),
        ],
        'iconColor': const Color(0xFF10B981),
        'description': S
            .of(context)
            .connectedServicesDesc, // TODO: Ajouter dans ARB
      },
      {
        'icon': LucideIcons.scale,
        'label': S.of(context).decisionSupport, // TODO: Ajouter dans ARB
        'route': '/decisions',
        'gradient': [
          const Color(0xFF6366F1).withOpacity(0.2),
          const Color(0xFF9333EA).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFF818CF8),
        'description': S
            .of(context)
            .decisionSupportDesc, // TODO: Ajouter dans ARB
      },
      {
        'icon': LucideIcons.trophy,
        'label': S.of(context).goalsGrowth, // TODO: Ajouter dans ARB
        'route': '/goals',
        'gradient': [
          const Color(0xFFF59E0B).withOpacity(0.2),
          const Color(0xFFEAB308).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFFFCD34D),
        'description': S.of(context).goalsGrowthDesc, // TODO: Ajouter dans ARB
      },
      {
        'icon': LucideIcons.zap,
        'label': S.of(context).automationRules, // TODO: Ajouter dans ARB
        'route': '/automation',
        'gradient': [
          const Color(0xFFFFB800).withOpacity(0.2),
          const Color(0xFFFF9800).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFFFFD93D),
        'description': S
            .of(context)
            .automationRulesDesc, // TODO: Ajouter dans ARB
      },
      {
        'icon': LucideIcons.award,
        'label': S.of(context).challenges, // TODO: Ajouter dans ARB
        'route': '/challenges',
        'gradient': [
          const Color(0xFF06B6D4).withOpacity(0.2),
          const Color(0xFF0891B2).withOpacity(0.2),
        ],
        'iconColor': const Color(0xFF06B6D4),
        'description': S.of(context).challengesDesc, // TODO: Ajouter dans ARB
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
          .fadeIn(
            delay: Duration(milliseconds: 500 + (index * 50)),
            duration: 500.ms,
          )
          .slideX(
            begin: -0.2,
            end: 0,
            delay: Duration(milliseconds: 500 + (index * 50)),
            duration: 500.ms,
          );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Données dynamiques : priorité au profil (GET /auth/me), sinon user (login)
    final userName = profile?.name ?? user?.name ?? '—';
    final userEmail = profile?.email ?? user?.email ?? '—';
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
          colors: isDark
              ? [
                  AppColors.primaryLight.withOpacity(0.6),
                  AppColors.primaryDarker.withOpacity(0.6),
                ]
              : [const Color(0xFFF7FBFF), const Color(0xFFE8F2FA)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withOpacity(0.2)
              : const Color(0xFFC1DAE8),
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
                                colors: [AppColors.cyan500, AppColors.blue500],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 16.0,
                            tablet: 18.0,
                            desktop: 20.0,
                          ),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9DBBCC,
                                  ).withOpacity(0.16),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (profile?.avatarUrl ?? '').isEmpty
                          ? Center(
                              child: Text(
                                initials.isNotEmpty ? initials : 'JD',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textWhite
                                      : const Color(0xFF102437),
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
                              color: isDark
                                  ? AppColors.textWhite
                                  : const Color(0xFF102437),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            S
                                .of(context)
                                .aiEnthusiast, // TODO: Ajouter dans ARB
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              color: isDark
                                  ? AppColors.textCyan200.withOpacity(0.7)
                                  : const Color(0xFF4B6780),
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
                          color: isDark
                              ? AppColors.cyan500.withOpacity(0.2)
                              : const Color(0xFFE7F3FA),
                          borderRadius: BorderRadius.circular(
                            isMobile ? 10 : 12,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.cyan500.withOpacity(0.3)
                                : const Color(0xFFC1DAE8),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: isDark
                              ? AppColors.cyan400
                              : const Color(0xFF0F7B99),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? 16 : 18,
          color: isDark ? AppColors.cyan400 : const Color(0xFF0F7B99),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: isDark
                  ? AppColors.textCyan200.withOpacity(0.7)
                  : const Color(0xFF5B778E),
              height: 1.3,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryLight.withOpacity(0.4),
                  AppColors.primaryDarker.withOpacity(0.4),
                ]
              : [const Color(0xFFF8FCFF), const Color(0xFFE6F1F8)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withOpacity(0.1)
              : const Color(0xFFC2D9E7),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textCyan200.withOpacity(0.6)
                        : const Color(0xFF5B778E),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              colors: isDark
                  ? [
                      const Color(0xFF1e4a66).withOpacity(0.4),
                      const Color(0xFF16384d).withOpacity(0.4),
                    ]
                  : [const Color(0xFFF8FCFF), const Color(0xFFEAF4FB)],
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
              color: _isHovered
                  ? (isDark
                        ? AppColors.cyan500.withOpacity(0.3)
                        : const Color(0xFF9CC5D9))
                  : (isDark
                        ? AppColors.cyan500.withOpacity(0.1)
                        : const Color(0xFFBFD4E3)),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 13.0,
                desktop: 14.0,
              ),
            ),
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
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      ),
                    ),
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
                            borderRadius: BorderRadius.circular(
                              Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 11.0,
                                desktop: 12.0,
                              ),
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.cyan500.withOpacity(0.2)
                                  : const Color(0xFFBFD4E3),
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
                        SizedBox(
                          width: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                        ),
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
                                  color: isDark
                                      ? AppColors.textWhite
                                      : const Color(0xFF1B3550),
                                ),
                              ),
                              SizedBox(
                                height: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 3.0,
                                  tablet: 4.0,
                                  desktop: 5.0,
                                ),
                              ),
                              Text(
                                widget.description,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  color: isDark
                                      ? AppColors.textCyan200.withOpacity(0.6)
                                      : const Color(0xFF627A8E),
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
                          color: isDark
                              ? AppColors.cyan400
                              : const Color(0xFF0B6A88),
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
