import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shell.dart';

/// e.g. "Marco Rossi" → "Marco R."
String briefingInvestorShortName(String fullName) {
  final t = fullName.trim();
  if (t.isEmpty) return '';
  final parts = t.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0];
  final last = parts.last;
  if (last.isEmpty) return parts.first;
  return '${parts.first} ${last[0]}.';
}

/// Query string for all briefing tab routes and `/briefing-loading`.
/// [investorCity] / [investorCountry] come from Meeting Setup (investor geography).
String briefingTabsQuery(
  String sessionId,
  String investorName, {
  String investorCompany = '',
  String investorCity = '',
  String investorCountry = '',
  String userEquity = '',
  String userValuation = '',
  String meetingFormat = '',
}) {
  return 'sessionId=${Uri.encodeComponent(sessionId)}'
      '&investorName=${Uri.encodeComponent(investorName)}'
      '&investorCompany=${Uri.encodeComponent(investorCompany)}'
      '&investorCity=${Uri.encodeComponent(investorCity)}'
      '&investorCountry=${Uri.encodeComponent(investorCountry)}'
      '&userEquity=${Uri.encodeComponent(userEquity)}'
      '&userValuation=${Uri.encodeComponent(userValuation)}'
      '&meetingFormat=${Uri.encodeComponent(meetingFormat)}';
}

void goBriefingTab(
  BuildContext context,
  int index,
  String sessionId,
  String investorName, {
  String investorCompany = '',
  String investorCity = '',
  String investorCountry = '',
  String userEquity = '',
  String userValuation = '',
  String meetingFormat = '',
}) {
  final q = briefingTabsQuery(
    sessionId,
    investorName,
    investorCompany: investorCompany,
    investorCity: investorCity,
    investorCountry: investorCountry,
    userEquity: userEquity,
    userValuation: userValuation,
    meetingFormat: meetingFormat,
  );
  switch (index) {
    case 0:
      context.go('/briefing/culture?$q');
      break;
    case 1:
      context.go('/briefing/psych?$q');
      break;
    case 2:
      context.go('/briefing/negotiation?$q');
      break;
    case 3:
      context.go('/briefing/offer?$q');
      break;
    case 4:
      context.go('/briefing/image?$q');
      break;
    case 5:
      context.go('/briefing/location?$q');
      break;
    default:
      break;
  }
}

const List<String> kBriefingTabLabels = [
  '🌍 Culture',
  '🧠 Profile',
  '🤝 Negotiate',
  '📊 Offer',
  '👔 Image',
  '📍 Location',
];

/// Même dégradé que Home / Meeting Setup — à utiliser pour tous les onglets briefing.
class BriefingGradientScaffold extends StatelessWidget {
  const BriefingGradientScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return AppShellGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class BriefingAvaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BriefingAvaAppBar({
    super.key,
    required this.investorName,
    this.onBack,
  });

  final String investorName;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: onBack ?? () => context.pop(),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textCyan200,
          size: 18,
        ),
      ),
      title: const Text(
        'AVA Briefing',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              investorName,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.cyan400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: AppColors.cyan500.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

class BriefingHorizontalTabBar extends StatelessWidget {
  const BriefingHorizontalTabBar({
    super.key,
    required this.activeIndex,
    required this.sessionId,
    required this.investorName,
    this.investorCompany = '',
    this.investorCity = '',
    this.investorCountry = '',
    this.userEquity = '',
    this.userValuation = '',
    this.meetingFormat = '',
  });

  final int activeIndex;
  final String sessionId;
  final String investorName;
  final String investorCompany;
  final String investorCity;
  final String investorCountry;
  final String userEquity;
  final String userValuation;
  final String meetingFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.cyan500.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: kBriefingTabLabels.length,
        itemBuilder: (context, i) {
          final active = i == activeIndex;
          return GestureDetector(
            onTap: () => goBriefingTab(
                  context,
                  i,
                  sessionId,
                  investorName,
                  investorCompany: investorCompany,
                  investorCity: investorCity,
                  investorCountry: investorCountry,
                  userEquity: userEquity,
                  userValuation: userValuation,
                  meetingFormat: meetingFormat,
                ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: active ? AppColors.buttonGradient : null,
                color: active ? null : AppColors.primaryDarker,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : AppColors.cyan500.withValues(alpha: 0.28),
                ),
              ),
              child: Center(
                child: Text(
                  kBriefingTabLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textCyan200,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
