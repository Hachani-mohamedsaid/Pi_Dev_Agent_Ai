import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/l10n/app_strings.dart';

class PreOnboardingPage extends StatefulWidget {
  const PreOnboardingPage({super.key});

  @override
  State<PreOnboardingPage> createState() => _PreOnboardingPageState();
}

class _PreOnboardingPageState extends State<PreOnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final List<AnimationController> _controllers;
  late final AnimationController _bgController;
  int _page = 0;

  static const _prefKey = 'hasSeenPreOnboarding';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // start first page animation
    scheduleMicrotask(() => _controllers[0].forward());

    _pageController.addListener(() {
      final p = _pageController.page ?? _page.toDouble();
      final int newPage = p.round();
      if (newPage != _page) {
        setState(() => _page = newPage);
        for (var i = 0; i < _controllers.length; i++) {
          if (i == newPage) {
            _controllers[i].forward();
          } else {
            _controllers[i].reset();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers) c.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) context.go('/login');
  }

  Widget _buildPage({
    required int index,
    required Widget illustration,
    required String title,
    required String subtitle,
    Widget? actions,
  }) {
    final anim = _controllers[index];
    final isMobile = Responsive.isMobile(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: Listenable.merge([anim, _bgController, _pageController]),
          builder: (context, child) {
            // parallax offset based on page position
            final page =
                (_pageController.hasClients && _pageController.page != null)
                ? _pageController.page!
                : _page.toDouble();
            final parallax = (page - index) * width * 0.2;

            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 48,
                vertical: isMobile ? 12 : 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isMobile ? 20 : 40),
                    Transform.translate(
                      offset: Offset(parallax, 0),
                      child: Transform.scale(
                        scale: 1.0 + 0.03 * anim.value,
                        child: SizedBox(
                          height: isMobile ? 180 : 280,
                          child: illustration,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 32),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeIn,
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 16,
                              color: AppColors.textCyan200.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 36),
                    if (actions != null) actions,
                    SizedBox(height: isMobile ? 20 : 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final t = _bgController.value;
          final colorA = Color.lerp(
            AppColors.primaryLight,
            AppColors.blue500,
            t,
          )!.withOpacity(0.95);
          final colorB = Color.lerp(
            AppColors.primaryDarker,
            AppColors.cyan500,
            t,
          )!.withOpacity(0.95);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorA, colorB],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    children: [
                      _buildPage(
                        index: 0,
                        illustration: _IllustrationBox(
                          icon: Icons.auto_awesome,
                          color: AppColors.cyan400,
                        ),
                        title: AppStrings.tr(context, 'welcomeToAva'),
                        subtitle: AppStrings.tr(context, 'welcomeSubtitle'),
                        actions: _PageFooter(
                          isLast: false,
                          onNext: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          onSkip: null,
                        ),
                      ),
                      _buildPage(
                        index: 1,
                        illustration: _IllustrationBox(
                          icon: Icons.checklist_rounded,
                          color: AppColors.blue500,
                        ),
                        title: AppStrings.tr(context, 'keyFeatures'),
                        subtitle: AppStrings.tr(context, 'keyFeaturesSubtitle'),
                        actions: _FeaturesList(controller: _controllers[1]),
                      ),
                      _buildPage(
                        index: 2,
                        illustration: _IllustrationBox(
                          icon: Icons.rocket_launch,
                          color: AppColors.cyan500,
                        ),
                        title: AppStrings.tr(context, 'getStarted'),
                        subtitle: AppStrings.tr(context, 'getStartedSubtitle'),
                        actions: _PageFooter(
                          isLast: true,
                          onNext: _complete,
                          onSkip: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(_prefKey, true);
                            if (mounted) context.go('/login');
                          },
                        ),
                      ),
                    ],
                  ),

                  // Page indicator
                  Positioned(
                    bottom: isMobile ? 28 : 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) {
                          final p =
                              (_pageController.hasClients &&
                                  _pageController.page != null)
                              ? _pageController.page!
                              : _page.toDouble();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                              final selected = (p - i).abs() < 0.5;
                              final size = selected ? 12.0 : 8.0;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.textWhite
                                      : AppColors.cyan400.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IllustrationBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IllustrationBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Icon(icon, size: 120, color: color)),
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  final bool isLast;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  const _PageFooter({required this.isLast, this.onNext, this.onSkip});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 18 : 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isLast)
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppStrings.tr(context, 'next')),
            ),
          if (isLast) ...[
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppStrings.tr(context, 'createAccount')),
            ),
            const SizedBox(width: 12),
            TextButton(onPressed: onSkip, child: Text(AppStrings.tr(context, 'signInAction'))),
          ],
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  final AnimationController controller;
  const _FeaturesList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final features = [
      {
        'icon': Icons.chat_bubble,
        'title': AppStrings.tr(context, 'smartReplies'),
        'desc': AppStrings.tr(context, 'smartRepliesDesc'),
      },
      {
        'icon': Icons.calendar_today,
        'title': AppStrings.tr(context, 'calendarSync'),
        'desc': AppStrings.tr(context, 'calendarSyncDesc'),
      },
      {
        'icon': Icons.lock,
        'title': AppStrings.tr(context, 'privateByDesign'),
        'desc': AppStrings.tr(context, 'privateByDesignDesc'),
      },
    ];

    return Column(
      children: List.generate(features.length, (i) {
        final start = i * 0.12;
        final end = start + 0.45;
        final anim = CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(anim),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 10),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Icon(
                    features[i]['icon'] as IconData,
                    color: AppColors.cyan400,
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          features[i]['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          features[i]['desc'] as String,
                          style: TextStyle(
                            color: AppColors.textCyan200.withOpacity(0.9),
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
      }),
    );
  }
}
