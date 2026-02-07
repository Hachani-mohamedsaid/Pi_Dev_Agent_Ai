import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/logo_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Always go to login; onboarding appears after login on first open
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                          color: AppColors.cyan500.withOpacity(0.1),
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
                          color: AppColors.blue500.withOpacity(0.1),
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
                  const LogoWidget()
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
                        'Ava',
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
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
                  SizedBox(height: isMobile ? 8 : 12),
                  // Subtitle
                  Text(
                        'Your Personal AI Assistant',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          color: AppColors.textCyan200.withOpacity(0.8),
                        ),
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
}
