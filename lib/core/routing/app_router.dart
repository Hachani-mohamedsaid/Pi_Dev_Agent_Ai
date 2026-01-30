import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/register_page.dart';
import '../../presentation/pages/reset_password_page.dart';
<<<<<<< HEAD
=======
import '../../presentation/pages/reset_password_confirm_page.dart';
>>>>>>> c3cf2c9 ( Flutter project v1)
import '../../presentation/pages/home_screen.dart';
import '../../presentation/pages/profile_screen.dart';
import '../../presentation/pages/edit_profile_page.dart';
import '../../presentation/pages/language_page.dart';
import '../../presentation/pages/notifications_page.dart';
import '../../presentation/pages/privacy_security_page.dart';
import '../../presentation/pages/change_password_page.dart';
<<<<<<< HEAD
import '../../presentation/pages/voice_assistant_page.dart';
=======
>>>>>>> c3cf2c9 ( Flutter project v1)
import '../../injection_container.dart';

// Custom page transition - fade and scale from center
Page<T> _fadeScaleTransition<T extends Object?>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurveTween(curve: Curves.easeOutCubic).animate(animation),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const SplashPage(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        // Use a unique key based on navigation to ensure animations always play
        final key = state.uri.queryParameters['animate'] ?? 'default';
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: LoginPage(
            key: ValueKey('login_$key'),
            controller: InjectionContainer.instance.buildAuthController(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: RegisterPage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: ResetPasswordPage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
<<<<<<< HEAD
=======
      path: '/reset-password/confirm',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: ResetPasswordConfirmPage(
          controller: InjectionContainer.instance.buildAuthController(),
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
    ),
    GoRoute(
>>>>>>> c3cf2c9 ( Flutter project v1)
      path: '/home',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: HomeScreen(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: ProfileScreen(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: EditProfilePage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
      path: '/language',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const LanguagePage(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const NotificationsPage(),
      ),
    ),
    GoRoute(
      path: '/privacy-security',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const PrivacySecurityPage(),
      ),
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const ChangePasswordPage(),
      ),
    ),
<<<<<<< HEAD
    GoRoute(
      path: '/voice-assistant',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: VoiceAssistantPage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
=======
>>>>>>> c3cf2c9 ( Flutter project v1)
  ],
);
