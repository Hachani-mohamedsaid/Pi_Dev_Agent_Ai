import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/pre_onboarding_storage.dart';
import '../../injection_container.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authCtrl = InjectionContainer.instance.buildAuthController();
    await authCtrl.loadCurrentUser();
    if (!mounted) return;

    final seen = await PreOnboardingStorage.hasSeenPreOnboarding;
    final isAuth = authCtrl.isAuthenticated;

    if (!mounted) return;
    if (isAuth) {
      context.go('/home');
    } else if (!seen) {
      context.go('/intro');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final splashGradient = isDark
        ? AppColors.primaryGradient
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FCFF), Color(0xFFEAF4FB), Color(0xFFF3F8FC)],
          );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(gradient: splashGradient),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.25,
              child:
                  Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: Responsive.screenWidth(context) * 0.4,
                          tablet: 300,
                          desktop: 400,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: Responsive.screenWidth(context) * 0.4,
                          tablet: 300,
                          desktop: 400,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan500.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(delay: 200.ms, duration: 600.ms),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child:
                  Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: Responsive.screenWidth(context) * 0.4,
                          tablet: 300,
                          desktop: 400,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: Responsive.screenWidth(context) * 0.4,
                          tablet: 300,
                          desktop: 400,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue500.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .scale(delay: 400.ms, duration: 600.ms),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Robot Icon
                  _buildSplashLogo(context)
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: 600.ms)
                      .then(delay: 200.ms),
                  SizedBox(height: isMobile ? 24 : 32),
                  // App Name
                  Text(
                        'AVA',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10,
                          height: 1,
                          fontFamily: 'Georgia',
                          shadows: [
                            Shadow(
                              color: Color(0x6622D3EE),
                              blurRadius: 22,
                              offset: Offset(0, 4),
                            ),
                          ],
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF12263A),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 500.ms,
                        duration: 600.ms,
                      ),
                  SizedBox(height: isMobile ? 10 : 14),
                  // Subtitle
                  Text(
                        'Your Personal AI Assistant',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.8,
                          height: 1.4,
                          color: isDark
                              ? AppColors.textCyan200.withValues(alpha: 0.75)
                              : const Color(0xFF3F6983),
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 700.ms,
                        duration: 600.ms,
                      ),
                  SizedBox(height: isMobile ? 48 : 64),
                  // Loading indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) =>
                          Container(
                                width: isMobile ? 8 : 10,
                                height: isMobile ? 8 : 10,
                                margin: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 4 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan400,
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .scale(
                                delay: Duration(milliseconds: index * 200),
                                duration: 1000.ms,
                                begin: const Offset(1, 1),
                                end: const Offset(1.5, 1.5),
                              )
                              .then()
                              .scale(
                                duration: 1000.ms,
                                begin: const Offset(1.5, 1.5),
                                end: const Offset(1, 1),
                              )
                              .fade(
                                delay: Duration(milliseconds: index * 200),
                                duration: 1000.ms,
                                begin: 0.5,
                                end: 1,
                              )
                              .then()
                              .fade(duration: 1000.ms, begin: 1, end: 0.5),
                    ),
                  ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplashLogo(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final size = isMobile ? 92.0 : 108.0;

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/ava_logo.png',
        fit: BoxFit.contain,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF12263A),
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackMonogram(isMobile ? 26.0 : 30.0),
      ),
    );
  }

  Widget _fallbackMonogram(double radius) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.logoGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
