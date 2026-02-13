import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/pre_onboarding_storage.dart';
import '../../../core/l10n/app_strings.dart';
import 'widgets/animated_gradient_background.dart';
import 'widgets/animated_page_indicator.dart';
import 'widgets/animated_simple_icon.dart';
import 'widgets/intro_illustration.dart';
import 'widgets/scale_press_button.dart';

/// Illustration professionnelle pour la page Ava (Lottie ou GIF dans assets).
const String _introAgentAsset = 'assets/lottie/agent_face.json';

/// Premium pre-login onboarding. Shown only once to unauthenticated users.
/// Completely independent from post-login onboarding - no shared code.
class PreOnboardingPage extends StatefulWidget {
  const PreOnboardingPage({super.key});

  @override
  State<PreOnboardingPage> createState() => _PreOnboardingPageState();
}

class _PreOnboardingPageState extends State<PreOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _elasticCurve = Curves.easeOutCubic;

  Future<void> _completeAndGoToLogin() async {
    await PreOnboardingStorage.markAsSeen();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _goToRegister() async {
    await PreOnboardingStorage.markAsSeen();
    if (!mounted) return;
    context.go('/register');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _WelcomePage(
                  pageController: _pageController,
                  onNext: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 450),
                    curve: _elasticCurve,
                  ),
                ),
                _FeaturesPage(
                  pageController: _pageController,
                  onNext: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 450),
                    curve: _elasticCurve,
                  ),
                ),
                _GetStartedPage(
                  onRegister: _goToRegister,
                  onLogin: _completeAndGoToLogin,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AnimatedPageIndicator(
                    currentIndex: _currentPage,
                    itemCount: 3,
                    activeColor: AppColors.cyan400,
                    inactiveColor: AppColors.textCyan200.withOpacity(0.35),
                    size: 8,
                    activeSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE 1 - Welcome
// ---------------------------------------------------------------------------

class _WelcomePage extends StatefulWidget {
  const _WelcomePage({
    required this.pageController,
    required this.onNext,
  });

  final PageController pageController;
  final VoidCallback onNext;

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleOffset;
  late Animation<double> _descOpacity;
  late Animation<double> _illustrationScale;
  late Animation<double> _illustrationOpacity;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleOffset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _descOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOut),
      ),
    );
    _illustrationScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _illustrationOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _ParallaxWrapper(
                    pageController: widget.pageController,
                    pageIndex: 0,
                    parallaxFactor: 0.15,
                    child: FadeTransition(
                      opacity: _illustrationOpacity,
                      child: ScaleTransition(
                        scale: _illustrationScale,
                        child: const IntroIllustration(
                          assetPath: _introAgentAsset,
                          size: 280,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Title - slide up + fade (300ms)
                  _ParallaxWrapper(
                    pageController: widget.pageController,
                    pageIndex: 0,
                    parallaxFactor: 0.08,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleOffset,
                        child: Text(
                          AppStrings.tr(context, 'ava'),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textWhite,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description - delayed fade (150ms after title)
                  FadeTransition(
                    opacity: _descOpacity,
                    child: Text(
                      AppStrings.tr(context, 'yourPersonalAIAssistant'),
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textCyan200.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 2),
                  ScalePressButton(
                    onPressed: widget.onNext,
                    backgroundColor: AppColors.cyan500,
                    foregroundColor: AppColors.textWhite,
                    child: Text(AppStrings.tr(context, 'next')),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE 2 - Features (staggered cards)
// ---------------------------------------------------------------------------

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

class _FeaturesPage extends StatefulWidget {
  const _FeaturesPage({
    required this.pageController,
    required this.onNext,
  });

  final PageController pageController;
  final VoidCallback onNext;

  @override
  State<_FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<_FeaturesPage>
    with TickerProviderStateMixin {
  static List<_FeatureData> _features(BuildContext context) => [
    _FeatureData(
      Icons.mic_rounded,
      AppStrings.tr(context, 'voiceAssistant'),
      'Talk naturally with AI. Get instant answers and control your tasks by voice.',
    ),
    _FeatureData(
      Icons.auto_awesome_rounded,
      AppStrings.tr(context, 'smartInsights'),
      'AI analyzes your patterns and suggests actions to boost your productivity.',
    ),
    _FeatureData(
      Icons.security_rounded,
      AppStrings.tr(context, 'privacyFirst'),
      'Your data stays on your device. Enterprise-grade security for your peace of mind.',
    ),
  ];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacities;
  late List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _opacities = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
            ))
        .toList();
    _slides = _controllers
        .map((c) => Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              AppStrings.tr(context, 'powerfulFeatures'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tr(context, 'everythingInOnePlace'),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textCyan200.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 40),
            ...List.generate(3, (i) {
              final f = _features(context)[i];
              return FadeTransition(
                opacity: _opacities[i],
                child: SlideTransition(
                  position: _slides[i],
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FeatureCard(
                      icon: f.icon,
                      title: f.title,
                      description: f.description,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            ScalePressButton(
              onPressed: widget.onNext,
              backgroundColor: AppColors.cyan500,
              foregroundColor: AppColors.textWhite,
              child: Text(AppStrings.tr(context, 'next')),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan500.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.cyan400, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textCyan200.withOpacity(0.85),
                        height: 1.4,
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
}

// ---------------------------------------------------------------------------
// PAGE 3 - Get Started
// ---------------------------------------------------------------------------

class _GetStartedPage extends StatefulWidget {
  const _GetStartedPage({
    required this.onRegister,
    required this.onLogin,
  });

  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  State<_GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<_GetStartedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _lottieScale;
  late Animation<double> _lottieOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textOffset;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lottieScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _lottieOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _textOffset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              FadeTransition(
                opacity: _lottieOpacity,
                child: ScaleTransition(
                  scale: _lottieScale,
                  child: const AnimatedSimpleIcon(
                    icon: Icons.rocket_launch_rounded,
                    size: 120,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textOffset,
                  child: Text(
                    AppStrings.tr(context, 'readyToTransform'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  AppStrings.tr(context, 'joinThousands'),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textCyan200.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 1),
              ScalePressButton(
                onPressed: widget.onRegister,
                backgroundColor: AppColors.cyan500,
                foregroundColor: AppColors.textWhite,
                child: Text(AppStrings.tr(context, 'createAccount')),
              ),
              const SizedBox(height: 16),
              ScalePressButton(
                onPressed: widget.onLogin,
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textCyan200,
                border: Border.all(
                  color: AppColors.cyan500.withOpacity(0.5),
                  width: 1.5,
                ),
                child: Text(AppStrings.tr(context, 'alreadyHaveAccount')),
              ),
              const SizedBox(height: 56),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Parallax wrapper
// ---------------------------------------------------------------------------

class _ParallaxWrapper extends StatelessWidget {
  const _ParallaxWrapper({
    required this.pageController,
    required this.pageIndex,
    required this.parallaxFactor,
    required this.child,
  });

  final PageController pageController;
  final int pageIndex;
  final double parallaxFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double offset = 0;
        if (pageController.hasClients) {
          final pos = pageController.page ?? 0;
          offset = (pos - pageIndex) * parallaxFactor * 80;
        }
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: child,
    );
  }
}
