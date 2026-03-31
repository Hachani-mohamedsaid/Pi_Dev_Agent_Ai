import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ava_theme.dart';
import 'briefing_shared.dart';

/// Other briefing tabs (Profile, Negotiate, …) until dedicated pages exist.
class BriefingTabPlaceholderScreen extends StatelessWidget {
  const BriefingTabPlaceholderScreen({
    super.key,
    required this.activeTabIndex,
    required this.sessionId,
    required this.investorName,
    required this.title,
    this.subtitle = 'Content will appear here.',
    this.investorCompany = '',
    this.investorCity = '',
    this.investorCountry = '',
    this.userEquity = '',
    this.userValuation = '',
    this.meetingFormat = '',
  });

  final int activeTabIndex;
  final String sessionId;
  final String investorName;
  final String title;
  final String subtitle;
  final String investorCompany;
  final String investorCity;
  final String investorCountry;
  final String userEquity;
  final String userValuation;
  final String meetingFormat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvaColors.bg,
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(investorName),
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          BriefingHorizontalTabBar(
            activeIndex: activeTabIndex,
            sessionId: sessionId,
            investorName: investorName,
            investorCompany: investorCompany,
            investorCity: investorCity,
            investorCountry: investorCountry,
            userEquity: userEquity,
            userValuation: userValuation,
            meetingFormat: meetingFormat,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AvaText.display.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AvaText.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
