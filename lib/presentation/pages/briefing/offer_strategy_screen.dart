import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/briefing_offer_cache.dart';
import '../../../features/meeting_intelligence/models/offer_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 7 — Offer strategy. POST `/meetings/:id/briefing/offer` (cached).
class OfferStrategyScreen extends StatefulWidget {
  const OfferStrategyScreen({
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
  State<OfferStrategyScreen> createState() => _OfferStrategyScreenState();
}

class _OfferStrategyScreenState extends State<OfferStrategyScreen>
    with SingleTickerProviderStateMixin {
  OfferResult? _result;
  bool _loading = true;
  String? _error;

  late AnimationController _gaugeCtrl;
  late Animation<double> _gaugeAnim;

  static const int _offerTabIndex = 3;

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  @override
  void initState() {
    super.initState();
    _gaugeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gaugeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _gaugeCtrl.dispose();
    super.dispose();
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

    final cached = BriefingOfferCache.get(id);
    if (cached != null) {
      setState(() {
        _result = cached;
        _loading = false;
        _error = null;
      });
      _gaugeCtrl.forward(from: 0);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.postOfferBriefing(id);
      BriefingOfferCache.put(id, data);
      if (!mounted) return;
      setState(() {
        _result = data;
        _loading = false;
      });
      _gaugeCtrl.forward(from: 0);
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
            activeIndex: _offerTabIndex,
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AvaColors.gold,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) return _errorState();
    return _content(_result!);
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AvaColors.muted, size: 36),
            const SizedBox(height: 16),
            const Text('Could not load offer analysis', style: AvaText.caption),
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

  Widget _content(OfferResult r) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _gaugeSection(r),
        const SizedBox(height: 10),
        _avaBubble(
          'Your offer is ${r.verdictWord} — '
          'here is the full breakdown and what to expect in the room.',
        ),
        const SizedBox(height: 10),
        _comparisonTable(r),
        const SizedBox(height: 10),
        _infoCard(
          label: 'MARKET COMPARISON',
          labelColor: AvaColors.blue,
          text: r.marketComparison,
        ),
        const SizedBox(height: 10),
        _strategicAdviceCard(r.strategicAdvice),
        const SizedBox(height: 10),
        _counterCard(r.recommendedCounter),
        const SizedBox(height: 10),
        _nextStepCard(
          subtitle: 'Executive image coaching →',
          onTap: () => goBriefingTab(
            context,
            4,
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

  Widget _gaugeSection(OfferResult r) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _gaugeAnim,
          builder: (context, _) {
            final t = _gaugeAnim.value;
            final arcFraction = t * r.fairScore / 100;
            final scoreDisplay = (r.fairScore * t).round();
            return CustomPaint(
              size: const Size(180, 100),
              painter: _GaugePainter(
                value: arcFraction.clamp(0.0, 1.0),
                score: scoreDisplay,
                gaugeColor: r.gaugeColor,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: r.verdictColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: r.verdictColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                r.verdictLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: r.verdictColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FAIR SCORE',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 2.5,
                color: AvaColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            child: Text(text, style: AvaText.body.copyWith(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _comparisonTable(OfferResult r) {
    return Container(
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AvaColors.faint.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'METRIC',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: AvaColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'YOUR OFFER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: AvaColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'MARKET',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: AvaColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _tableRow(
            label: 'Equity',
            value: widget.userEquity,
            valueColor: AvaColors.gold,
            market: r.fairEquityRange,
            marketColor: AvaColors.green,
          ),
          _tableRow(
            label: 'Valuation',
            value: widget.userValuation,
            valueColor: r.verdictColor,
            market: r.verdictLabel,
            marketColor: r.verdictColor,
          ),
          _tableRow(
            label: 'Walk-away',
            value: r.walkAwayLimit,
            valueColor: AvaColors.red,
            market: '—',
            marketColor: AvaColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _tableRow({
    required String label,
    required String value,
    required Color valueColor,
    required String market,
    required Color marketColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AvaColors.border.withValues(alpha: 0.9),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AvaText.caption),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              market,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: marketColor),
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

  Widget _strategicAdviceCard(String advice) {
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
            '🎯  STRATEGIC ADVICE',
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
                  advice,
                  style: AvaText.body.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterCard(String counter) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '→ ',
            style: TextStyle(
              color: AvaColors.green,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECOMMENDED COUNTER',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 2,
                    color: AvaColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(counter, style: AvaText.body.copyWith(fontSize: 12)),
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

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.score,
    required this.gaugeColor,
  });

  final double value;
  final int score;
  final Color gaugeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;
    final r = size.width * 0.43;

    const startAngle = math.pi;
    const sweepTotal = math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = const Color(0xFF2A3048)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepTotal * value,
        false,
        Paint()
          ..color = gaugeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: gaugeColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height - 4),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.score != score ||
      old.gaugeColor != gaugeColor;
}
