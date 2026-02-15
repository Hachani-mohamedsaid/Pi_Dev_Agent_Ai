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
import '../../presentation/pages/notifications_center_page.dart';
import '../../presentation/pages/privacy_security_page.dart';
import '../../presentation/pages/help_support_page.dart';
import '../../presentation/pages/change_password_page.dart';
import '../../presentation/pages/voice_assistant_page.dart';
import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/suggestions_feed_page.dart';
import '../../presentation/pages/agenda_page.dart';
import '../../presentation/pages/emails_page.dart';
import '../../presentation/pages/history_page.dart';
import '../../presentation/pages/travel_page.dart';
import '../../presentation/pages/actions_hub_page.dart';
import '../../presentation/pages/automation_rules_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/intro/pre_onboarding_page.dart';
import '../../presentation/pages/insights_page.dart';
import '../../presentation/pages/connected_services_page.dart';
import '../../presentation/pages/decision_support_page.dart';
import '../../presentation/pages/goals_page.dart';
import '../../presentation/pages/work_proposals_page.dart';
import '../../presentation/pages/work_proposals_dashboard_page.dart';
import '../../presentation/pages/project_analysis_page.dart';
import '../../presentation/pages/how_to_work_page.dart';
import '../../presentation/pages/work_proposal_details_page.dart';
import '../../data/models/work_proposal_model.dart';
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
      path: '/onboarding',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: '/intro',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const PreOnboardingPage(),
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
      path: '/help-support',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const HelpSupportPage(),
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
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const ChatPage(),
      ),
    ),
    // Notifications Center (from home screen bell)
    GoRoute(
      path: '/notifications-center',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const NotificationsCenterPage(),
      ),
    ),
    GoRoute(
      path: '/suggestions',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const SuggestionsFeedPage(),
      ),
    ),
    GoRoute(
      path: '/agenda',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const AgendaPage(),
      ),
    ),
    GoRoute(
      path: '/emails',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const EmailsPage(),
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const HistoryPage(),
      ),
    ),
    GoRoute(
      path: '/travel',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const TravelPage(),
      ),
    ),
    GoRoute(
      path: '/actions',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const ActionsHubPage(),
      ),
    ),
    GoRoute(
      path: '/automation',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const AutomationRulesPage(),
      ),
    ),
    GoRoute(
      path: '/insights',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const InsightsPage(),
      ),
    ),
    GoRoute(
      path: '/services',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const ConnectedServicesPage(),
      ),
    ),
    GoRoute(
      path: '/decisions',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const DecisionSupportPage(),
      ),
    ),
    GoRoute(
      path: '/goals',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const GoalsPage(),
      ),
    ),
    GoRoute(
      path: '/work-proposals',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const WorkProposalsPage(),
      ),
    ),
    GoRoute(
      path: '/work-proposals-dashboard',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const WorkProposalsDashboardPage(),
      ),
    ),
    GoRoute(
      path: '/project-analysis',
      pageBuilder: (context, state) {
        final proposal = state.extra as WorkProposal?;
        if (proposal == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const WorkProposalsPage(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: ProjectAnalysisPage(proposal: proposal),
        );
      },
    ),
    GoRoute(
      path: '/work-proposal-details',
      pageBuilder: (context, state) {
        final proposal = state.extra as WorkProposal?;
        if (proposal == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const WorkProposalsPage(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: WorkProposalDetailsPage(proposal: proposal),
        );
      },
    ),
    GoRoute(
      path: '/how-to-work',
      pageBuilder: (context, state) {
        final proposal = state.extra as WorkProposal?;
        if (proposal == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const WorkProposalsPage(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: HowToWorkPage(proposal: proposal),
        );
      },
    ),
  ],
);

// Placeholder page for routes that will be implemented later
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Coming soon...',
                  style: TextStyle(fontSize: 16, color: Color(0xFFA5F3FC)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
