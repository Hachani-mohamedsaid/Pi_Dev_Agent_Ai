import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/briefing_culture_cache.dart';
import '../../../features/meeting_intelligence/models/cultural_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 4 — Cultural briefing tab (Culture). Data: POST /meetings/:id/briefing/culture (cached).
class CulturalBriefingScreen extends StatefulWidget {
  const CulturalBriefingScreen({
    super.key,
    required this.sessionId,
    this.investorName = 'Investor',
    this.investorCompany = '',
    this.investorCity = '',
    this.investorCountry = '',
    this.userEquity = '',
    this.userValuation = '',
    this.meetingFormat = '',
  });

  final String sessionId;
  final String investorName;
  final String investorCompany;
  final String investorCity;
  final String investorCountry;
  final String userEquity;
  final String userValuation;
  final String meetingFormat;

  @override
  State<CulturalBriefingScreen> createState() => _CulturalBriefingScreenState();
}

class _CulturalBriefingScreenState extends State<CulturalBriefingScreen> {
  CulturalResult? _result;
  bool _loading = true;
  String? _error;

  static const int _cultureTabIndex = 0;

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  String _cultureIntroCopy() {
    final city = widget.investorCity.trim();
    final country = widget.investorCountry.trim();
    final fmt = widget.meetingFormat.trim();
    String geo;
    if (city.isNotEmpty && country.isNotEmpty) {
      geo = '$city, $country';
    } else if (country.isNotEmpty) {
      geo = country;
    } else if (city.isNotEmpty) {
      geo = city;
    } else {
      geo = 'your meeting context';
    }
    final fmtBit =
        fmt.isNotEmpty ? ' Your format is $fmt — advice below matches that.' : '';
    return 'Your investor meeting is anchored in $geo.$fmtBit '
        'Here is how to show up so the room reads you as prepared and respectful.';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.sessionId.trim();
    if (id.isEmpty) {
      setState(() {
        _error = 'Missing session';
        _loading = false;
      });
      return;
    }

    final cached = BriefingCultureCache.get(id);
    if (cached != null) {
      setState(() {
        _result = cached;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.postCultureBriefing(id);
      BriefingCultureCache.put(id, data);
      if (!mounted) return;
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvaColors.bg,
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(widget.investorName),
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          BriefingHorizontalTabBar(
            activeIndex: _cultureTabIndex,
            sessionId: widget.sessionId,
            investorName: widget.investorName,
            investorCompany: widget.investorCompany,
            investorCity: widget.investorCity,
            investorCountry: widget.investorCountry,
            userEquity: widget.userEquity,
            userValuation: widget.userValuation,
            meetingFormat: widget.meetingFormat,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();
    return _content(_result!);
  }

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AvaColors.gold,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Loading cultural briefing…',
            style: AvaText.caption,
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AvaColors.muted,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load briefing',
              style: AvaText.caption,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: AvaText.caption.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 20),
            avaGoldBtn('Retry', _load),
          ],
        ),
      ),
    );
  }

  Widget _content(CulturalResult r) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _avaBubble(_cultureIntroCopy()),
        const SizedBox(height: 10),
        _dotCard(
          label: "✅  DO'S",
          labelColor: AvaColors.green,
          items: r.dos,
          dotColor: AvaColors.green,
        ),
        const SizedBox(height: 10),
        _dotCard(
          label: '❌  AVOID',
          labelColor: AvaColors.red,
          items: r.donts,
          dotColor: AvaColors.red,
        ),
        const SizedBox(height: 10),
        _infoCard(
          label: 'COMMUNICATION STYLE',
          labelColor: AvaColors.blue,
          text: r.communicationStyle,
        ),
        const SizedBox(height: 10),
        _infoCard(
          label: 'NEGOTIATION APPROACH',
          labelColor: AvaColors.amber,
          text: r.negotiationApproach,
        ),
        const SizedBox(height: 10),
        _openingLineCard(r.openingLine),
        const SizedBox(height: 10),
        _meetingFlowCard(r.meetingFlow),
        const SizedBox(height: 10),
        _nextStepCard(
          subtitle: 'Investor psychological profile →',
          onTap: () => goBriefingTab(
            context,
            1,
            widget.sessionId,
            widget.investorName,
            investorCompany: widget.investorCompany,
            investorCity: widget.investorCity,
            investorCountry: widget.investorCountry,
            userEquity: widget.userEquity,
            userValuation: widget.userValuation,
            meetingFormat: widget.meetingFormat,
          ),
        ),
      ],
    );
  }

  Widget _avaBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avaAvatar(size: 28),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AvaColors.card,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AvaColors.border2),
            ),
            child: Text(
              text,
              style: AvaText.body.copyWith(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dotCard({
    required String label,
    required Color labelColor,
    required List<String> items,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: AvaText.body.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required Color labelColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: labelColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: AvaText.body.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _openingLineCard(String line) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '💬  OPENING LINE',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                  color: AvaColors.gold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: line));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard'),
                      backgroundColor: AvaColors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AvaColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AvaColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 9,
                      color: AvaColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            line,
            style: AvaText.body.copyWith(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetingFlowCard(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEETING FLOW',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: AvaColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, left: 4, right: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AvaColors.faint,
                        size: 14,
                      ),
                    ),
                  SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AvaColors.gold.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AvaColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AvaColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps[i],
                          style: const TextStyle(
                            fontSize: 9,
                            color: AvaColors.muted,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepCard({
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AvaColors.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT STEP',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 2,
                      color: AvaColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AvaText.caption),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AvaColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AvaColors.bg,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
