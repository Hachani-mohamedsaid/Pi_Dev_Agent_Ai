import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/services/meeting_service.dart';
import '../../services/n8n_email_service.dart';
import '../../features/phone_agent/data/phone_agent_mock_data.dart';
import '../state/auth_controller.dart';
import '../widgets/navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  final AuthController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _emailService = N8nEmailService();
  int _emailTotal = 0;
  int _emailHigh = 0;
  int _emailMedium = 0;
  int _emailLow = 0;
  int _emailDeadlines = 0;
  int _emailActionsRequired = 0;
  bool _emailSummaryLoading = true;

  /// Number of meetings today (null = loading).
  int? _meetingsTodayCount;
  final _meetingService = MeetingService();

  /// Tracks if we were the current route; used to reload when home becomes visible again.
  bool _wasCurrentRoute = false;

  late AnimationController _glowController1;
  late AnimationController _glowController2;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _orbitController;
  late List<AnimationController> _particleControllers;
  late List<AnimationController> _ringControllers;

  @override
  void initState() {
    super.initState();
    // Load current user if not already loaded
    if (widget.controller.currentUser == null) {
      widget.controller.loadCurrentUser();
    }
    // Email summary is loaded in didChangeDependencies when home becomes visible
    // (runs on first open and every time user navigates back to home)

    // Animation controllers for daily summary card
    _glowController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Particle animations
    _particleControllers = List.generate(10, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 4000 + (i * 500)),
      )..repeat();
    });

    // Ring animations
    _ringControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      )..repeat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload email summary whenever home becomes the current route (e.g. user switched back from another tab)
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent && !_wasCurrentRoute) {
      _wasCurrentRoute = true;
      _loadEmailSummary();
      _loadMeetingsToday();
    } else if (!isCurrent) {
      _wasCurrentRoute = false;
    }
  }

  @override
  void dispose() {
    _glowController1.dispose();
    _glowController2.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _orbitController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    for (var controller in _ringControllers) {
      controller.dispose();
    }
    _meetingService.dispose();
    super.dispose();
  }

  /// Loads dashboard counts from GET email-summary-stats only.
  /// Does NOT call email-summaries — that runs only when the Emails page is opened.
  Future<void> _loadEmailSummary() async {
    try {
      final stats = await _emailService.getEmailSummaryStats();
      if (!mounted) return;
      setState(() {
        _emailTotal = _toInt(stats['totalEmails']);
        _emailHigh = _toInt(stats['highPriority']);
        _emailMedium = _toInt(stats['mediumPriority']);
        _emailLow = _toInt(stats['lowPriority']);
        _emailDeadlines = _toInt(stats['deadlines']);
        _emailActionsRequired = _toInt(stats['requiredActions']);
        _emailSummaryLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _emailSummaryLoading = false);
    }
  }

  Future<void> _loadMeetingsToday() async {
    try {
      final meetings = await _meetingService.fetchMeetings();
      if (!mounted) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final count = meetings.where((m) {
        final start = m.startTime;
        final startDay = DateTime(start.year, start.month, start.day);
        return startDay == today;
      }).length;
      setState(() => _meetingsTodayCount = count);
    } catch (_) {
      if (mounted) setState(() => _meetingsTodayCount = 0);
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.tr(context, 'goodMorning');
    if (hour < 18) return AppStrings.tr(context, 'goodAfternoon');
    return AppStrings.tr(context, 'goodEvening');
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = [
      AppStrings.tr(context, 'monday'),
      AppStrings.tr(context, 'tuesday'),
      AppStrings.tr(context, 'wednesday'),
      AppStrings.tr(context, 'thursday'),
      AppStrings.tr(context, 'friday'),
      AppStrings.tr(context, 'saturday'),
      AppStrings.tr(context, 'sunday'),
    ];
    final months = [
      AppStrings.tr(context, 'january'),
      AppStrings.tr(context, 'february'),
      AppStrings.tr(context, 'march'),
      AppStrings.tr(context, 'april'),
      AppStrings.tr(context, 'may'),
      AppStrings.tr(context, 'june'),
      AppStrings.tr(context, 'july'),
      AppStrings.tr(context, 'august'),
      AppStrings.tr(context, 'september'),
      AppStrings.tr(context, 'october'),
      AppStrings.tr(context, 'november'),
      AppStrings.tr(context, 'december'),
    ];
    return '${AppStrings.tr(context, 'todayIs')} ${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _getShortDate() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenWidth = Responsive.screenWidth(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
    // Max content width for large screens (tablet/desktop) to keep layout readable
    final maxContentWidth = Responsive.getResponsiveValue(
      context,
      mobile: screenWidth,
      tablet: 600.0,
      desktop: 700.0,
    );

    final userName =
        widget.controller.currentUser?.name ?? AppStrings.tr(context, 'user');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeader(context, isMobile, userName, padding),

                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Daily Summary Card
                        _buildDailySummaryCard(context, isMobile),

                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Smart Suggestions Button
                        _buildSmartSuggestionsButton(context, isMobile),

                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Suggested Action Card
                        _buildSuggestedActionCard(context, isMobile),

                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Quick Actions Section
                        _buildQuickActionsSection(context, isMobile),
                      ],
                    ),
                  ),

                  // Navigation Bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: NavigationBarWidget(currentPath: '/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isMobile,
    String userName,
    double padding,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.getResponsiveValue(
          context,
          mobile: 6.0,
          tablet: 8.0,
          desktop: 12.0,
        ),
        bottom: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 32.0,
        ),
      ),
      child: Stack(
        children: [
          // Notification Bell - Top Right
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => context.push('/notifications-center'),
              child:
                  Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1e4a66).withOpacity(0.6),
                              const Color(0xFF16384d).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
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
                            // Notification Badge
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 22.0,
                                ),
                                height: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 22.0,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEC4899),
                                      Color(0xFFEF4444),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 9.0,
                                        tablet: 10.0,
                                        desktop: 11.0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        delay: 400.ms,
                        duration: 500.ms,
                      ),
            ),
          ),

          // Header Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting(context)}, $userName',
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 8.0,
                  desktop: 12.0,
                ),
              ),
              Text(
                _getCurrentDate(),
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 13.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                  color: AppColors.textCyan200.withOpacity(0.7),
                ),
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 16.0,
                ),
              ),
              // AI Status Indicator
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 7.0,
                          tablet: 8.0,
                          desktop: 9.0,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 7.0,
                          tablet: 8.0,
                          desktop: 9.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400,
                          shape: BoxShape.circle,
                        ),
                        transform: Matrix4.identity()
                          ..scale(0.6 + (_pulseController.value * 0.4)),
                      );
                    },
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 7.0,
                      desktop: 8.0,
                    ),
                  ),
                  Text(
                    AppStrings.tr(context, 'upToDate'),
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      color: AppColors.cyan400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard(BuildContext context, bool isMobile) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = Responsive.getResponsiveValue(
      context,
      mobile: math.min(320.0, screenHeight * 0.4),
      tablet: math.min(360.0, screenHeight * 0.35),
      desktop: math.min(400.0, screenHeight * 0.3),
    );

    return Container(
      constraints: BoxConstraints(
        minHeight: math.min(
          Responsive.getResponsiveValue(
            context,
            mobile: 280.0,
            tablet: 320.0,
            desktop: 360.0,
          ),
          cardHeight,
        ),
        maxHeight: cardHeight,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 22.0,
            tablet: 24.0,
            desktop: 28.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 22.0,
            tablet: 24.0,
            desktop: 28.0,
          ),
        ),
        child: Stack(
          children: [
            // Base gradient background
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0],
                  colors: [
                    Color(0xFF0a1f2e),
                    Color(0xFF0f2a3d),
                    Color(0xFF14354c),
                    Color(0xFF19405b),
                    Color(0xFF1e4a66),
                    Color(0xFF235573),
                    Color(0xFF286082),
                    Color(0xFF2d6b91),
                  ],
                ),
              ),
            ),

            // Dark vignette at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: Responsive.getResponsiveValue(
                context,
                mobile: 100.0,
                tablet: 114.0,
                desktop: 128.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF050A0F).withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Animated Gradient Overlay 1 - Cyan glow
            AnimatedBuilder(
              animation: _glowController1,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.3, -0.8),
                        radius: 0.6.clamp(0.1, 1.0),
                        colors: [
                          const Color(0xFF00D4FF).withOpacity(
                            (0.4 * (0.5 + _glowController1.value * 0.4)).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Animated Gradient Overlay 2 - Blue accent
            AnimatedBuilder(
              animation: _glowController2,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.7, 0.8),
                        radius: 0.5.clamp(0.1, 1.0),
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(
                            (0.5 * (0.4 + _glowController2.value * 0.4)).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Pulsing center glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 160.0,
                      tablet: 180.0,
                      desktop: 200.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 160.0,
                      tablet: 180.0,
                      desktop: 200.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00D4FF).withOpacity(
                            (0.3 * (0.3 + _pulseController.value * 0.3)).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    transform: Matrix4.identity()
                      ..scale(0.8 + (_pulseController.value * 0.3)),
                  ),
                );
              },
            ),

            // Shimmer effect (LayoutBuilder must not be parent of Positioned — wrap in Stack)
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: Transform.translate(
                        offset: Offset(
                          -constraints.maxWidth +
                              (_shimmerController.value *
                                  constraints.maxWidth *
                                  2),
                          0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.5, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.03),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                  ],
                );
              },
            ),

            // Orbiting light particles
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: List.generate(8, (i) {
                    final angle = (i / 8) * math.pi * 2;
                    return AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        final rotation = _orbitController.value * 2 * math.pi;
                        final orbitRadius = Responsive.getResponsiveValue(
                          context,
                          mobile: 60.0,
                          tablet: 70.0,
                          desktop: 80.0,
                        );
                        final x = math.cos(angle + rotation) * orbitRadius;
                        final y = math.sin(angle + rotation) * orbitRadius;
                        final particleSize = Responsive.getResponsiveValue(
                          context,
                          mobile: 1.5,
                          tablet: 1.75,
                          desktop: 2.0,
                        );
                        return Positioned(
                          left: constraints.maxWidth / 2 + x - particleSize,
                          top: constraints.maxHeight / 2 + y - particleSize,
                          child: AnimatedBuilder(
                            animation:
                                _particleControllers[i %
                                    _particleControllers.length],
                            builder: (context, child) {
                              final scale =
                                  (1.0 +
                                          (_particleControllers[i %
                                                      _particleControllers
                                                          .length]
                                                  .value *
                                              0.5))
                                      .clamp(0.5, 2.0);
                              final opacity =
                                  (0.4 +
                                          (_particleControllers[i %
                                                      _particleControllers
                                                          .length]
                                                  .value *
                                              0.4))
                                      .clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 3.0,
                                    tablet: 3.5,
                                    desktop: 4.0,
                                  ),
                                  height: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 3.0,
                                    tablet: 3.5,
                                    desktop: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00D4FF,
                                    ).withOpacity(opacity),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00D4FF,
                                        ).withOpacity(0.8),
                                        blurRadius:
                                            Responsive.getResponsiveValue(
                                              context,
                                              mobile: 6.0,
                                              tablet: 7.0,
                                              desktop: 8.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),

            // Floating Particles
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: List.generate(10, (i) {
                    return AnimatedBuilder(
                      animation:
                          _particleControllers[i % _particleControllers.length],
                      builder: (context, child) {
                        final progress =
                            _particleControllers[i %
                                    _particleControllers.length]
                                .value;
                        final random = math.Random(i);
                        final startX =
                            random.nextDouble() * constraints.maxWidth;
                        final startY =
                            random.nextDouble() * constraints.maxHeight * 0.5;
                        final offsetX =
                            (random.nextDouble() * 15 - 7.5) * progress;
                        final offsetY = -20 * progress;
                        final opacity =
                            0.2 + (math.sin(progress * math.pi * 2) * 0.4);
                        final scale =
                            1.0 + (math.sin(progress * math.pi * 2) * 0.3);

                        return Positioned(
                          left: startX + offsetX,
                          top: startY + offsetY,
                          child: Transform.scale(
                            scale: scale.clamp(0.5, 2.0),
                            child: Container(
                              width:
                                  Responsive.getResponsiveValue(
                                    context,
                                    mobile: 2.0,
                                    tablet: 2.5,
                                    desktop: 3.0,
                                  ) +
                                  (random.nextDouble() *
                                      Responsive.getResponsiveValue(
                                        context,
                                        mobile: 4.0,
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      )),
                              height:
                                  Responsive.getResponsiveValue(
                                    context,
                                    mobile: 2.0,
                                    tablet: 2.5,
                                    desktop: 3.0,
                                  ) +
                                  (random.nextDouble() *
                                      Responsive.getResponsiveValue(
                                        context,
                                        mobile: 4.0,
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      )),
                              decoration: BoxDecoration(
                                color:
                                    (i % 2 == 0
                                            ? const Color(0xFF00D4FF)
                                            : const Color(0xFF3B82F6))
                                        .withOpacity(
                                          (opacity * 0.4).clamp(0.0, 1.0),
                                        ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00D4FF,
                                    ).withOpacity(0.6),
                                    blurRadius: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 4.0,
                                      tablet: 5.0,
                                      desktop: 6.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),

            // Expanding rings from center
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _ringControllers[i],
                builder: (context, child) {
                  final scale = (1.0 + (_ringControllers[i].value * 1.5)).clamp(
                    1.0,
                    3.0,
                  );
                  final opacity = (0.5 * (1 - _ringControllers[i].value)).clamp(
                    0.0,
                    1.0,
                  );
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 60.0,
                          tablet: 70.0,
                          desktop: 80.0,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 60.0,
                          tablet: 70.0,
                          desktop: 80.0,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF00D4FF,
                            ).withOpacity((opacity * 0.3).clamp(0.0, 1.0)),
                            width: Responsive.getResponsiveValue(
                              context,
                              mobile: 0.8,
                              tablet: 0.9,
                              desktop: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Dark cyan/blue patches at bottom
            Positioned(
              bottom: 0,
              left: 0,
              child: AnimatedBuilder(
                animation: _glowController1,
                builder: (context, child) {
                  return Container(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 100.0,
                      tablet: 114.0,
                      desktop: 128.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 75.0,
                      tablet: 85.0,
                      desktop: 96.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF080F19).withOpacity(
                            (0.8 * (0.6 + _glowController1.value * 0.3)).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _glowController2,
                builder: (context, child) {
                  return Container(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 88.0,
                      tablet: 100.0,
                      desktop: 112.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 63.0,
                      tablet: 71.0,
                      desktop: 80.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF0A141E).withOpacity(
                            (0.7 * (0.5 + _glowController2.value * 0.3)).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                },
              ),
            ),

            // LayoutBuilder must not be parent of Positioned — wrap in Stack
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      bottom: 16,
                      left: constraints.maxWidth / 2 - 72,
                      child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 115.0,
                          tablet: 130.0,
                          desktop: 144.0,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 51.0,
                          tablet: 57.0,
                          desktop: 64.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF060C14).withOpacity(
                                (0.6 * (0.4 + _pulseController.value * 0.3))
                                    .clamp(0.0, 1.0),
                              ),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    },
                  ),
                    ),
                  ],
                );
              },
            ),

            // Content
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(
                  Responsive.getResponsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          color: AppColors.cyan400,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 18.0,
                            tablet: 20.0,
                            desktop: 22.0,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 7.0,
                            desktop: 8.0,
                          ),
                        ),
                        Text(
                          AppStrings.tr(context, 'dailySummary'),
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 17.0,
                              tablet: 19.0,
                              desktop: 20.0,
                            ),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                    Text(
                      "You have one important meeting, two emails that need attention, and a time gap this afternoon that could be optimized.",
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        color: AppColors.textCyan200.withOpacity(0.8),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 16.0,
                      ),
                    ),
                    // Key Items - Use Flexible instead of Expanded to prevent overflow
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildKeyItem(
                            context,
                            isMobile,
                            LucideIcons.clock,
                            "Team meeting at 10:00",
                            0,
                          ),
                          SizedBox(
                            height: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 8.0,
                            ),
                          ),
                          _buildKeyItem(
                            context,
                            isMobile,
                            LucideIcons.mail,
                            "Urgent email from HR",
                            1,
                          ),
                          SizedBox(
                            height: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 8.0,
                            ),
                          ),
                          _buildKeyItem(
                            context,
                            isMobile,
                            LucideIcons.calendar,
                            "Free time between 15:00–16:30",
                            2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyItem(
    BuildContext context,
    bool isMobile,
    IconData icon,
    String text,
    int index,
  ) {
    return Container(
          padding: EdgeInsets.all(
            Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 11.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            border: Border.all(
              color: AppColors.cyan500.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 11.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  Container(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 30.0,
                      tablet: 32.0,
                      desktop: 36.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 30.0,
                      tablet: 32.0,
                      desktop: 36.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan500.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 8.0,
                          tablet: 9.0,
                          desktop: 10.0,
                        ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.cyan400,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 11.0,
                      desktop: 12.0,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 200 + (index * 100)),
          duration: 500.ms,
        )
        .slideX(
          begin: -0.2,
          end: 0,
          delay: Duration(milliseconds: 200 + (index * 100)),
          duration: 500.ms,
        );
  }

  Widget _buildSmartSuggestionsButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => context.push('/suggestions'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withOpacity(0.2),
              const Color(0xFFFFC107).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(
            Responsive.getResponsiveValue(
              context,
              mobile: 11.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.lightbulb,
              color: const Color(0xFFFFD700),
              size: Responsive.getResponsiveValue(
                context,
                mobile: 18.0,
                tablet: 20.0,
                desktop: 22.0,
              ),
            ),
            SizedBox(
              width: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 7.0,
                desktop: 8.0,
              ),
            ),
            Flexible(
              child: Text(
                AppStrings.tr(context, 'viewSmartSuggestions'),
                style: TextStyle(
                  color: const Color(0xFFFFE082),
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  ),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedActionCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        ),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      color: AppColors.cyan500.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 11.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.brain,
                      color: AppColors.cyan400,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 11.0,
                      desktop: 12.0,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr(context, 'suggestion'),
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
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 3.5,
                            desktop: 4.0,
                          ),
                        ),
                        Text(
                          "I can reorganize your afternoon to reduce context switching.",
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
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 20.0,
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                        ),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4FF).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(
                            Responsive.getResponsiveValue(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 9.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 5.0,
                                    tablet: 5.5,
                                    desktop: 6.0,
                                  ),
                                ),
                                Text(
                                  AppStrings.tr(context, 'confirm'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 7.0,
                      desktop: 8.0,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(
                            Responsive.getResponsiveValue(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 9.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.edit,
                                  color: AppColors.textCyan300,
                                  size: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 5.0,
                                    tablet: 5.5,
                                    desktop: 6.0,
                                  ),
                                ),
                                Text(
                                  AppStrings.tr(context, 'modify'),
                                  style: TextStyle(
                                    color: AppColors.textCyan300,
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 7.0,
                      desktop: 8.0,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 11.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(
                            Responsive.getResponsiveValue(
                              context,
                              mobile: 9.0,
                              tablet: 10.0,
                              desktop: 12.0,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.x,
                            color: AppColors.cyan400.withOpacity(0.7),
                            size: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 16.0,
                              desktop: 18.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isMobile) {
    final actions = [
      {
        'title': 'Meeting Hub',
        'icon': LucideIcons.video,
        'route': '/meetings',
        'color': const Color(0xFFA855F7),
        'colorLight': const Color(0xFF3B82F6),
      },
      {
        'title': 'Summarized Emails',
        'icon': LucideIcons.mail,
        'route': '/emails',
        'color': AppColors.cyan500,
        'colorLight': const Color(0xFF3B82F6),
      },
      {
        'title': AppStrings.tr(context, 'viewAIActivity'),
        'icon': LucideIcons.history,
        'route': '/history',
        'color': const Color(0xFFFFC107),
        'colorLight': const Color(0xFFFF9800),
      },
      {
        'title': AppStrings.tr(context, 'travelAndJourneys'),
        'icon': LucideIcons.car,
        'route': '/travel',
        'color': const Color(0xFFFF9800),
        'colorLight': const Color(0xFFFFC107),
      },
      {
        'title': AppStrings.tr(context, 'smartActionsHub'),
        'icon': LucideIcons.zap,
        'route': '/actions',
        'color': const Color(0xFFEC4899),
        'colorLight': const Color(0xFFA855F7),
      },
      {
        'title': 'AI Financial Simulation',
        'icon': LucideIcons.calculator,
        'route': '/advisor',
        'color': const Color(0xFF10B981),
        'colorLight': const Color(0xFF34D399),
      },
      {
        'title': 'Mon business',
        'icon': LucideIcons.briefcase,
        'route': '/my-business',
        'color': const Color(0xFF8B5CF6),
        'colorLight': const Color(0xFFA78BFA),
      },
      {
        'title': 'Phone Agent',
        'icon': LucideIcons.phone,
        'route': '/phone-agent',
        'color': const Color(0xFF06B6D4),
        'colorLight': const Color(0xFF22D3EE),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr(context, 'quickActions'),
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 17.0,
              tablet: 19.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(
          height: Responsive.getResponsiveValue(
            context,
            mobile: 10.0,
            tablet: 12.0,
            desktop: 16.0,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildSummarizedEmailsCard(context, isMobile),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
          ),
          child: _buildMeetingHubCard(context, isMobile),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
          ),
          child: _buildOngoingProjectsGrid(context, isMobile),
        ),
        ...actions.asMap().entries.map((entry) {
          if (entry.key == 1) return const SizedBox.shrink();
          if (entry.key == 0 || entry.key == 5 || entry.key == 6 || entry.key == 7) return const SizedBox.shrink();
          final index = entry.key;
          final action = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 16.0,
              ),
            ),
            child: _buildQuickActionItem(
              context,
              isMobile,
              action['title'] as String,
              action['icon'] as IconData,
              action['route'] as String,
              action['color'] as Color,
              action['colorLight'] as Color,
              index,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummarizedEmailsCard(BuildContext context, bool isMobile) {
    final r = Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0);
    return GestureDetector(
      onTap: () => context.push('/emails'),
      child: Container(
        padding: EdgeInsets.all(r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a1f2e),
              Color(0xFF14354c),
              Color(0xFF1e4a66),
              Color(0xFF19405b),
              Color(0xFF0f2a3d),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mail, color: AppColors.cyan400, size: r),
                SizedBox(width: r * 0.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summarized Emails',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(context, mobile: 17.0, tablet: 18.0, desktop: 20.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getShortDate(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textCyan200.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: r),
            Container(
              padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan400,
                    ),
                  ),
                  SizedBox(height: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriorityChip(context, _emailHigh, 'High', const Color(0xFFEF4444)),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                      Expanded(
                        child: _buildPriorityChip(context, _emailMedium, 'Medium', const Color(0xFFFACC15)),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                      Expanded(
                        child: _buildPriorityChip(context, _emailLow, 'Low', const Color(0xFF22C55E)),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatRow(context, 'Deadlines', _emailDeadlines, const Color(0xFFF97316)),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                      Expanded(
                        child: _buildStatRow(context, 'Actions', _emailActionsRequired, const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: r),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
              ),
              decoration: BoxDecoration(
                color: AppColors.cyan500.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan400.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Emails',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textCyan200,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.arrowRight, size: 16, color: AppColors.cyan400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Meeting Hub card (React-style): Video icon, title, subtitle, arrow → /meetings.
  Widget _buildMeetingHubCard(BuildContext context, bool isMobile) {
    final r = Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0);
    return GestureDetector(
      onTap: () => context.push('/meetings'),
      child: Container(
        padding: EdgeInsets.all(r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a1f2e),
              Color(0xFF0f2a3d),
              Color(0xFF14354c),
              Color(0xFF19405b),
              Color(0xFF1e4a66),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan500.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: Responsive.getResponsiveValue(context, mobile: 52.0, tablet: 56.0, desktop: 60.0),
              height: Responsive.getResponsiveValue(context, mobile: 52.0, tablet: 56.0, desktop: 60.0),
              decoration: BoxDecoration(
                color: AppColors.cyan500.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyan400.withOpacity(0.3)),
              ),
              child: Icon(LucideIcons.video, color: AppColors.cyan400, size: 28),
            ),
            SizedBox(width: r),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting Hub',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 17.0, tablet: 18.0, desktop: 20.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start or join with AI assistance',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                      color: AppColors.textCyan200.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: Responsive.getResponsiveValue(context, mobile: 38.0, tablet: 40.0, desktop: 44.0),
              height: Responsive.getResponsiveValue(context, mobile: 38.0, tablet: 40.0, desktop: 44.0),
              decoration: BoxDecoration(
                color: AppColors.cyan500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.chevronRight, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideX(begin: 0.02, end: 0, curve: Curves.easeOut);
  }

  Widget _buildPriorityChip(BuildContext context, int count, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan400.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: color.withOpacity(0.7), blurRadius: 6),
            ]),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan400.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
                  BoxShadow(color: color.withOpacity(0.7), blurRadius: 6),
                ]),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getOngoingProjectsData() {
    final phoneCalls = mockPhoneCalls;
    final phoneTotal = phoneCalls.length;
    final phoneImportant = phoneCalls.where((c) => c.priority == 'high').length;
    final meetingsText = _meetingsTodayCount != null
        ? '$_meetingsTodayCount meeting${_meetingsTodayCount == 1 ? '' : 's'} today'
        : null;
    return [
      {'title': 'Meeting Hub', 'subtitle': meetingsText, 'icon': LucideIcons.video, 'route': '/meetings', 'color': const Color(0xFFA855F7)},
      {'title': 'AI Financial Simulation', 'subtitle': null, 'icon': LucideIcons.calculator, 'route': '/advisor', 'color': const Color(0xFF10B981)},
      {'title': 'Mon business', 'subtitle': null, 'icon': LucideIcons.briefcase, 'route': '/my-business', 'color': const Color(0xFF8B5CF6)},
      {'title': 'Phone Agent', 'subtitle': '$phoneTotal calls • $phoneImportant important', 'icon': LucideIcons.phone, 'route': '/phone-agent', 'color': const Color(0xFF06B6D4)},
    ];
  }

  Widget _buildOngoingProjectsGrid(BuildContext context, bool isMobile) {
    final spacing = Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ongoing Projects',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 17.0, desktop: 18.0),
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'view all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.cyan400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Builder(
          builder: (context) {
            final data = _getOngoingProjectsData();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: spacing / 2),
                          child: _buildOngoingProjectCard(
                            context,
                            isMobile,
                            title: data[0]['title'] as String,
                            subtitle: data[0]['subtitle'] as String?,
                            icon: data[0]['icon'] as IconData,
                            route: data[0]['route'] as String,
                            color: data[0]['color'] as Color,
                            isHighlighted: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: spacing / 2),
                          child: _buildOngoingProjectCard(
                            context,
                            isMobile,
                            title: data[1]['title'] as String,
                            subtitle: data[1]['subtitle'] as String?,
                            icon: data[1]['icon'] as IconData,
                            route: data[1]['route'] as String,
                            color: data[1]['color'] as Color,
                            isHighlighted: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: spacing / 2),
                          child: _buildOngoingProjectCard(
                            context,
                            isMobile,
                            title: data[2]['title'] as String,
                            subtitle: data[2]['subtitle'] as String?,
                            icon: data[2]['icon'] as IconData,
                            route: data[2]['route'] as String,
                            color: data[2]['color'] as Color,
                            isHighlighted: false,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: spacing / 2),
                          child: _buildOngoingProjectCard(
                            context,
                            isMobile,
                            title: data[3]['title'] as String,
                            subtitle: data[3]['subtitle'] as String?,
                            icon: data[3]['icon'] as IconData,
                            route: data[3]['route'] as String,
                            color: data[3]['color'] as Color,
                            isHighlighted: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOngoingProjectCard(
    BuildContext context,
    bool isMobile, {
    required String title,
    required String? subtitle,
    required IconData icon,
    required String route,
    required Color color,
    required bool isHighlighted,
  }) {
    final r = Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0);
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: EdgeInsets.all(r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHighlighted
                ? [
                    const Color(0xFF1e4a66),
                    const Color(0xFF16384d),
                    const Color(0xFF0f2940),
                  ]
                : [
                    const Color(0xFF1e4a66).withOpacity(0.35),
                    const Color(0xFF16384d).withOpacity(0.35),
                  ],
            ),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
            color: isHighlighted ? AppColors.cyan500.withOpacity(0.35) : AppColors.cyan500.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(isHighlighted ? 0.35 : 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isHighlighted ? Colors.white : color, size: 22),
            ),
            SizedBox(height: r * 0.5),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : AppColors.textWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isHighlighted ? AppColors.textCyan200.withOpacity(0.85) : AppColors.textCyan200.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    bool isMobile,
    String title,
    IconData icon,
    String route,
    Color color,
    Color colorLight,
    int index,
  ) {
    return GestureDetector(
          onTap: () => context.go(route),
          child: Container(
            padding: EdgeInsets.all(
              Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1e4a66).withOpacity(0.4),
                  const Color(0xFF16384d).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              border: Border.all(
                color: AppColors.cyan500.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                          colors: [
                            color.withOpacity(0.2),
                            colorLight.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 22.0,
                          tablet: 24.0,
                          desktop: 26.0,
                        ),
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
                      child: Text(
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
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: AppColors.cyan400,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
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
