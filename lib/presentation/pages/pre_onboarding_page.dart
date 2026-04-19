import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../generated/l10n.dart';

// --- Top-level widgets for onboarding ---

// (Déplacé à la fin du fichier pour respecter l'ordre Dart)
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
            final page = (_pageController.hasClients && _pageController.page != null)
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
                        title: S.of(context).welcome,
                        subtitle: S.of(context).welcomeBack,
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
                        title: S.of(context).features,
                        subtitle: S.of(context).suggestions,
                        actions: _FeaturesList(controller: _controllers[1]),
                      ),
                      _buildPage(
                        index: 2,
                        illustration: _IllustrationBox(
                          icon: Icons.rocket_launch,
                          color: AppColors.cyan500,
                        ),
                        title: S.of(context).signUp,
                        subtitle: S.of(context).signInSubtitle,
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
                  Positioned(
                    bottom: isMobile ? 28 : 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) {
                          final p = (_pageController.hasClients && _pageController.page != null)
                              ? _pageController.page!
                              : _page.toDouble();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                              final selected = (p - i).abs() < 0.5;
                              final size = selected ? 12.0 : 8.0;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
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

