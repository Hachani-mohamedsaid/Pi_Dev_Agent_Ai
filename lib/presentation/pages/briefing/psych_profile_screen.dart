import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/briefing_psych_cache.dart';
import '../../../features/meeting_intelligence/models/psych_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 5 — Investor psychological profile. POST `/meetings/:id/briefing/psych` (cached).
class PsychProfileScreen extends StatefulWidget {
  const PsychProfileScreen({
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
  State<PsychProfileScreen> createState() => _PsychProfileScreenState();
}

class _PsychProfileScreenState extends State<PsychProfileScreen> {
  PsychResult? _result;
  bool _loading = true;
  String? _error;

  static const int _psychTabIndex = 1;

  static const List<Color> _traitChipColors = [
    AvaColors.blue,
    AvaColors.gold,
    AvaColors.green,
    AvaColors.amber,
  ];

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

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

    final cached = BriefingPsychCache.get(id);
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
      final data = await _api.postPsychBriefing(id);
      BriefingPsychCache.put(id, data);
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
    return BriefingGradientScaffold(
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(widget.investorName),
        onBack: () => goBriefingBack(
          context,
          _psychTabIndex,
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
      body: Column(
        children: [
          BriefingHorizontalTabBar(
            activeIndex: _psychTabIndex,
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
            'Loading psychological profile…',
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
              'Could not load profile',
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

  Widget _content(PsychResult r) {
    final traits = _fourTraits(r.dominantTraits);
    final objections = _threeStrings(r.likelyObjections);
    final questions = _twoStrings(r.questionsToAsk);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (r.confidenceLevel.toLowerCase() == 'low') ...[
          _disclaimerBanner(),
          const SizedBox(height: 10),
        ],
        _profileBanner(r, traits),
        const SizedBox(height: 10),
        _avaBubble(
          'Here is a complete behavioral profile for your investor. '
          'Use this to tailor every word you say in that room.',
        ),
        const SizedBox(height: 10),
        _infoCard(
          label: 'COMMUNICATION PREFERENCE',
          labelColor: AvaColors.blue,
          borderColor: AvaColors.blue.withValues(alpha: 0.25),
          text: r.communicationPreference,
        ),
        const SizedBox(height: 10),
        _infoCard(
          label: 'DECISION STYLE',
          labelColor: AvaColors.amber,
          borderColor: AvaColors.amber.withValues(alpha: 0.25),
          text: r.decisionStyle,
        ),
        const SizedBox(height: 10),
        _objectionsCard(objections),
        const SizedBox(height: 10),
        _questionsCard(questions),
        const SizedBox(height: 10),
        _approachCard(r.howToApproach),
        const SizedBox(height: 10),
        _nextStepCard(
          subtitle: 'Practice negotiation simulation →',
          onTap: () {
            final q = briefingTabsQuery(
              widget.sessionId,
              widget.investorName,
              investorCompany: widget.investorCompany,
              investorCity: widget.investorCity,
              userEquity: widget.userEquity,
              userValuation: widget.userValuation,
            );
            final pt = Uri.encodeComponent(r.personalityType);
            context.go('/briefing/negotiation?$q&personalityType=$pt');
          },
        ),
      ],
    );
  }

  /// Exactly four slots; missing API values show an em dash.
  List<String> _fourTraits(List<String> raw) {
    final out = raw.take(4).toList();
    while (out.length < 4) {
      out.add('—');
    }
    return out;
  }

  List<String> _threeStrings(List<String> raw) {
    final out = raw.take(3).toList();
    while (out.length < 3) {
      out.add('—');
    }
    return out;
  }

  List<String> _twoStrings(List<String> raw) {
    final out = raw.take(2).toList();
    while (out.length < 2) {
      out.add('—');
    }
    return out;
  }

  Widget _disclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AvaColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AvaColors.amber.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AvaColors.amber,
            size: 14,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Limited investor data — profile based on sector norms. '
              'Add bio or LinkedIn text for a precise analysis.',
              style: TextStyle(
                fontSize: 11,
                color: AvaColors.amber,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileBanner(PsychResult r, List<String> traitsFour) {
    final parts = widget.investorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final String initials;
    if (parts.length >= 2) {
      initials =
          '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].length >= 2) {
      initials = parts[0].substring(0, 2).toUpperCase();
    } else if (parts.isNotEmpty) {
      initials = '${parts[0][0]}·'.toUpperCase();
    } else {
      initials = '··';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1020), Color(0xFF07090E)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AvaColors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AvaColors.blue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AvaColors.blue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AvaColors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.investorName,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AvaColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.investorCompany} · ${widget.investorCity}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AvaColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AvaColors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AvaColors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        r.personalityType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AvaColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: traitsFour.asMap().entries.map((e) {
              final color =
                  _traitChipColors[e.key % _traitChipColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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

  Widget _infoCard({
    required String label,
    required Color labelColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
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

  Widget _objectionsCard(List<String> objections) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️  LIKELY OBJECTIONS',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: AvaColors.amber,
            ),
          ),
          const SizedBox(height: 10),
          ...objections.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < objections.length - 1 ? 9 : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AvaColors.amber.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AvaColors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AvaColors.amber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '"${e.value}"',
                          style: AvaText.body.copyWith(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
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

  Widget _questionsCard(List<String> questions) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💬  QUESTIONS TO ASK HIM',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: AvaColors.blue,
            ),
          ),
          const SizedBox(height: 10),
          ...questions.asMap().entries.map(
                (e) => Container(
                  margin: EdgeInsets.only(
                    bottom: e.key < questions.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AvaColors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AvaColors.blue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '→ ',
                        style: TextStyle(
                          color: AvaColors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '"${e.value}"',
                          style: AvaText.body.copyWith(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
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

  Widget _approachCard(String approach) {
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
          const Text(
            '🎯  HOW TO APPROACH',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: AvaColors.gold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avaAvatar(size: 26),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  approach,
                  style: AvaText.body.copyWith(fontSize: 12),
                ),
              ),
            ],
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
          border: Border.all(color: AvaColors.gold.withValues(alpha: 0.25)),
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
