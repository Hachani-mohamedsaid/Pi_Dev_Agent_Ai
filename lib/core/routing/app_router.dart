import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/api_config.dart'
    show resetPasswordConfirmPath, verifyEmailConfirmPath;
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/register_page.dart';
import '../../presentation/pages/reset_password_page.dart';
import '../../presentation/pages/reset_password_confirm_page.dart';
import '../../presentation/pages/verify_email_confirm_page.dart';
import '../../presentation/pages/home_screen.dart';
import '../../presentation/pages/profile_screen.dart';
import '../../presentation/pages/edit_profile_page.dart';
import '../../presentation/pages/language_page.dart';
import '../../presentation/pages/notifications_page.dart';
import '../../presentation/pages/privacy_security_page.dart';
import '../../presentation/pages/change_password_page.dart';
import '../../presentation/pages/voice_assistant_page.dart';
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
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

/// Redirige les URLs avec espace encodé (%20) vers la route correcte (ex. lien email mal formé).
String? _redirectTrailingSpace(BuildContext context, GoRouterState state) {
  final path = state.uri.path.replaceAll('%20', '').trim();
  if (path == verifyEmailConfirmPath &&
      state.uri.path != verifyEmailConfirmPath) {
    final q = state.uri.hasQuery ? '?${state.uri.query}' : '';
    return '$verifyEmailConfirmPath$q';
  }
  if (path == resetPasswordConfirmPath &&
      state.uri.path != resetPasswordConfirmPath) {
    final q = state.uri.hasQuery ? '?${state.uri.query}' : '';
    return '$resetPasswordConfirmPath$q';
  }
  return null;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _redirectTrailingSpace,
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
      path: resetPasswordConfirmPath,
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: ResetPasswordConfirmPage(
          controller: InjectionContainer.instance.buildAuthController(),
          token: state.uri.queryParameters['token'],
        ),
      ),
    ),
    GoRoute(
      path: verifyEmailConfirmPath,
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: VerifyEmailConfirmPage(
          controller: InjectionContainer.instance.buildAuthController(),
          token: state.uri.queryParameters['token'],
        ),
      ),
    ),
    GoRoute(
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
        child: PrivacySecurityPage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: ChangePasswordPage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
      ),
    ),
    GoRoute(
      path: '/voice-assistant',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: VoiceAssistantPage(
          chatDataSource: InjectionContainer.instance.buildChatDataSource(),
        ),
      ),
    ),
  ],
);
