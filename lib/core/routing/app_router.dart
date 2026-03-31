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
import '../../presentation/pages/subscription_page.dart';
import '../../presentation/pages/subscription_success_page.dart';
import '../../presentation/pages/challenges_screen.dart';
import '../../presentation/pages/change_password_page.dart';
import '../../presentation/pages/voice_assistant_page.dart';
import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/suggestions_feed_page.dart';
import '../../presentation/pages/meeting_setup_screen.dart';
import '../../presentation/pages/market_intelligence_form_screen.dart';
import '../../presentation/pages/market_intel_swipe_screen.dart';
import '../../presentation/pages/briefing_loading_screen.dart';
import '../../presentation/pages/briefing/cultural_briefing_screen.dart';
import '../../presentation/pages/briefing/psych_profile_screen.dart';
import '../../presentation/pages/briefing/negotiation_simulator_screen.dart';
import '../../presentation/pages/briefing/offer_strategy_screen.dart';
import '../../presentation/pages/briefing/executive_image_screen.dart';
import '../../presentation/pages/briefing/location_advisor_screen.dart';
import '../../presentation/pages/briefing/executive_briefing_screen.dart';
import '../../features/meeting_intelligence/models/ava_session.dart';
import '../../presentation/pages/meeting_detail_page.dart';
import '../../presentation/pages/agenda_page.dart';
import '../../features/meeting_hub/screens/meeting_hub_screen.dart';
import '../../features/meeting_hub/screens/active_meeting_screen.dart';
import '../../features/meeting_hub/screens/meeting_transcript_screen.dart';
import '../../features/meeting_hub/models/meeting_model.dart';
import '../../presentation/pages/emails_page.dart';
import '../../presentation/pages/history_page.dart';
import '../../presentation/pages/travel_page.dart';
import '../../presentation/pages/actions_hub_page.dart';
import '../../presentation/pages/automation_rules_page.dart';
import '../../presentation/pages/finance_page.dart';
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
import '../../presentation/pages/create_job_page.dart';
import '../../presentation/pages/evaluation_status_page.dart';
import '../../presentation/pages/candidatures_page.dart';
import '../../presentation/pages/evaluation_detail_page.dart';
import '../../data/models/evaluation.dart';
import '../../presentation/pages/work_proposal_details_page.dart';
import '../../presentation/widgets/premium_feature_gate.dart';
import '../../data/models/work_proposal_model.dart';
import '../../injection_container.dart';
import '../../features/financial_advisor/models/advisor_report_model.dart';
import '../../features/financial_advisor/screens/advisor_page.dart';
import '../../features/financial_advisor/screens/advisor_result_page.dart';
import '../../features/financial_advisor/screens/advisor_project_details_page.dart';
import '../../features/my_business/models/business_session.dart';
import '../../features/my_business/screens/business_url_screen.dart';
import '../../features/my_business/screens/dashboard_style_screen.dart';
import '../../features/my_business/screens/business_dashboard_screen.dart';
import '../../features/phone_agent/models/phone_call_model.dart';
import '../../features/phone_agent/screens/phone_agent_screen.dart';
import '../../features/phone_agent/screens/phone_agent_call_detail_screen.dart';
import '../../features/social_media/screens/social_media_brief_screen.dart';

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
      path: '/challenges',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const ChallengesScreen(),
      ),
    ),
    GoRoute(
      path: '/subscription',
      pageBuilder: (context, state) {
        final activePlan = state.uri.queryParameters['activePlan'];
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: SubscriptionPage(activePlan: activePlan),
        );
      },
    ),
    GoRoute(
      path: '/subscription/success',
      pageBuilder: (context, state) {
        final plan = state.uri.queryParameters['plan'] ?? '';
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: SubscriptionSuccessPage(plan: plan),
        );
      },
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
        child: PremiumFeatureGate(
          child: VoiceAssistantPage(
            chatDataSource: InjectionContainer.instance.buildChatDataSource(),
          ),
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
    GoRoute(
      path: '/chat-hub',
      pageBuilder: (context, state) {
        final session = state.extra as AvaSession?;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: ChatPage(avaSession: session),
        );
      },
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
        child: SuggestionsFeedPage(
          controller: InjectionContainer.instance.buildAuthController(),
        ),
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
      path: '/investor-meeting-setup',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const MeetingSetupScreen(),
      ),
    ),
    GoRoute(
      path: '/market-intelligence',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: MarketIntelligenceFormScreen(
            sessionId: q['sessionId'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/market-intelligence/swipe',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is! Map) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const MarketIntelligenceFormScreen(),
          );
        }
        final m = Map<String, dynamic>.from(extra);
        final numRaw = m['proposedValuationNum'];
        final numVal = numRaw is num ? numRaw.toDouble() : 0.0;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: MarketIntelSwipeScreen(
            sessionId: m['sessionId']?.toString() ?? '',
            proposedValuation: m['proposedValuation']?.toString() ?? '€ 0',
            proposedValuationNum: numVal,
            proposedEquity: m['proposedEquity']?.toString() ?? '15%',
            sector: m['sector']?.toString() ?? 'FinTech',
            stage: m['stage']?.toString() ?? 'Seed',
            geography: m['geography']?.toString() ?? 'Europe',
            valuationBarLabel:
                m['valuationBarLabel']?.toString() ?? '€${numVal.round()}',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing-loading',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        final sessionId = q['sessionId'] ?? '';
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: BriefingLoadingScreen(
            sessionId: sessionId,
            investorName: q['investorName'] ?? '',
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            meetingFormat: q['meetingFormat'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing/culture',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        final extra = state.extra as AvaSession?;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: CulturalBriefingScreen(
            sessionId: q['sessionId'] ?? extra?.sessionId ?? '',
            investorName: q['investorName'] ?? extra?.investorName ?? 'Investor',
            investorCompany:
                q['investorCompany'] ?? extra?.investorCompany ?? '',
            investorCity: q['investorCity'] ?? extra?.city ?? '',
            investorCountry: q['investorCountry'] ?? extra?.country ?? '',
            userEquity: q['userEquity'] ?? extra?.userEquity ?? '',
            userValuation: q['userValuation'] ?? extra?.userValuation ?? '',
            meetingFormat: q['meetingFormat'] ?? extra?.meetingFormat ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing/psych',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: PsychProfileScreen(
            sessionId: q['sessionId'] ?? '',
            investorName: q['investorName'] ?? 'Investor',
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            meetingFormat: q['meetingFormat'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing/negotiation',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: NegotiationSimulatorScreen(
            sessionId: q['sessionId'] ?? '',
            investorName: q['investorName'] ?? 'Investor',
            personalityType: q['personalityType'],
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            meetingFormat: q['meetingFormat'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing/offer',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: OfferStrategyScreen(
            sessionId: q['sessionId'] ?? '',
            investorName: q['investorName'] ?? 'Investor',
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            meetingFormat: q['meetingFormat'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing/image',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: ExecutiveImageScreen(
            sessionId: q['sessionId'] ?? '',
            investorName: q['investorName'] ?? 'Investor',
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            meetingFormat: q['meetingFormat'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/briefing/location',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: LocationAdvisorScreen(
            sessionId: q['sessionId'] ?? '',
            investorName: q['investorName'] ?? 'Investor',
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            city: q['city'],
            meetingType: q['meetingFormat'] ?? q['meetingType'] ?? 'Formal',
          ),
        );
      },
    ),
    GoRoute(
      path: '/report',
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: ExecutiveBriefingScreen(
            sessionId: q['sessionId'] ?? '',
            investorName: q['investorName'] ?? 'Investor',
            investorCompany: q['investorCompany'] ?? '',
            investorCity: q['investorCity'] ?? '',
            investorCountry: q['investorCountry'] ?? '',
            userEquity: q['userEquity'] ?? '',
            userValuation: q['userValuation'] ?? '',
            meetingFormat: q['meetingFormat'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/meetings',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const PremiumFeatureGate(child: MeetingHubScreen()),
      ),
    ),
    GoRoute(
      path: '/active-meeting',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: ActiveMeetingScreen(
            roomID: extra?['roomID'] as String? ?? '',
            userID: extra?['userID'] as String? ?? '',
            userName: extra?['userName'] as String? ?? 'User',
            isStart: extra?['isStart'] as bool? ?? true,
          ),
        );
      },
    ),
    GoRoute(
      path: '/meeting-transcript/:meetingId',
      pageBuilder: (context, state) {
        final meetingId = state.pathParameters['meetingId'] ?? 'current';
        final fullTranscript = state.extra as List<TranscriptLineModel>?;
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: MeetingTranscriptScreen(
            meetingId: meetingId,
            fullTranscript: fullTranscript,
          ),
        );
      },
    ),
    GoRoute(
      path: '/meeting/:meetingId',
      pageBuilder: (context, state) {
        final meetingId = state.pathParameters['meetingId'] ?? '';
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: MeetingDetailPage(meetingId: meetingId),
        );
      },
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
      path: '/finance',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const FinancePage(),
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
      path: '/create-job',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const CreateJobPage(),
      ),
    ),
    GoRoute(
      path: '/candidatures',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const CandidaturesPage(),
      ),
    ),
    GoRoute(
      path: '/evaluation-detail',
      pageBuilder: (context, state) {
        final evaluation = state.extra as Evaluation?;
        if (evaluation == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const CandidaturesPage(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: EvaluationDetailPage(evaluation: evaluation),
        );
      },
    ),
    GoRoute(
      path: '/evaluation-status',
      pageBuilder: (context, state) {
        final id = state.uri.queryParameters['id'] ?? '';
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: EvaluationStatusPage(evaluationId: id),
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
    GoRoute(
      path: '/advisor',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const AdvisorPage(),
      ),
    ),
    GoRoute(
      path: '/advisor-result',
      pageBuilder: (context, state) {
        final report = state.extra as AdvisorReportModel?;
        if (report == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const AdvisorPage(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: AdvisorResultPage(report: report),
        );
      },
    ),
    GoRoute(
      path: '/advisor-project-details',
      pageBuilder: (context, state) {
        final report = state.extra as AdvisorReportModel?;
        if (report == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const AdvisorPage(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: AdvisorProjectDetailsPage(report: report),
        );
      },
    ),
    GoRoute(
      path: '/my-business',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const BusinessUrlScreen(),
      ),
    ),
    GoRoute(
      path: '/my-business/style',
      pageBuilder: (context, state) {
        final websiteUrl = state.extra as String? ?? '';
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: DashboardStyleScreen(websiteUrl: websiteUrl),
        );
      },
    ),
    GoRoute(
      path: '/my-business/dashboard',
      pageBuilder: (context, state) {
        final session = state.extra as BusinessSession?;
        if (session == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const BusinessUrlScreen(),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: BusinessDashboardScreen(session: session),
        );
      },
    ),
    GoRoute(
      path: '/phone-agent',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const PremiumFeatureGate(child: PhoneAgentScreen()),
      ),
    ),
    GoRoute(
      path: '/social-media',
      pageBuilder: (context, state) => _fadeScaleTransition(
        context: context,
        state: state,
        child: const SocialMediaBriefScreen(),
      ),
    ),
    GoRoute(
      path: '/phone-agent-call',
      pageBuilder: (context, state) {
        final call = state.extra as PhoneCallModel?;
        if (call == null) {
          return _fadeScaleTransition(
            context: context,
            state: state,
            child: const PremiumFeatureGate(child: PhoneAgentScreen()),
          );
        }
        return _fadeScaleTransition(
          context: context,
          state: state,
          child: PremiumFeatureGate(
            child: PhoneAgentCallDetailScreen(call: call),
          ),
        );
      },
    ),
  ],
);

// Placeholder page for routes that will be implemented later
// ignore: unused_element
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
