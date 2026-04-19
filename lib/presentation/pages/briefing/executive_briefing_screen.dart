import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/models/report_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 10 — Executive briefing report (generate + poll + export).
class ExecutiveBriefingScreen extends StatefulWidget {
  const ExecutiveBriefingScreen({
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
  State<ExecutiveBriefingScreen> createState() =>
      _ExecutiveBriefingScreenState();
}

class _SectionDef {
  const _SectionDef({
    required this.emoji,
    required this.name,
    required this.summary,
    required this.statusKey,
  });

  final String emoji;
  final String name;
  final String Function(ReportResult r) summary;
  final String Function(SectionStatuses s) statusKey;
}

final _kSections = <_SectionDef>[
  _SectionDef(
    emoji: '🌍',
    name: 'Cultural',
    summary: (r) => r.culturalSummary,
    statusKey: (s) => s.cultural,
  ),
  _SectionDef(
    emoji: '🧠',
    name: 'Profile',
    summary: (r) => r.profileSummary,
    statusKey: (s) => s.psych,
  ),
  _SectionDef(
    emoji: '🤝',
    name: 'Negotiation',
    summary: (r) => r.negotiationSummary,
    statusKey: (s) => s.negotiation,
  ),
  _SectionDef(
    emoji: '📊',
    name: 'Offer',
    summary: (r) => r.offerSummary,
    statusKey: (s) => s.offer,
  ),
  _SectionDef(
    emoji: '👔',
    name: 'Image',
    summary: (r) => r.imageSummary,
    statusKey: (s) => s.image,
  ),
  _SectionDef(
    emoji: '📍',
    name: 'Location',
    summary: (r) => r.locationSummary,
    statusKey: (s) => s.location,
  ),
];

class _ExecutiveBriefingScreenState extends State<ExecutiveBriefingScreen>
    with SingleTickerProviderStateMixin {
  ReportResult? _result;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  int _pollCount = 0;
  bool _exporting = false;

  static const int _maxPolls = 120;

  late AnimationController _gaugeCtrl;
  late Animation<double> _gaugeAnim;

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  @override
  void initState() {
    super.initState();
    _gaugeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _gaugeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeOut));
    unawaited(_startReportFlow());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _gaugeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startReportFlow() async {
    final id = widget.sessionId.trim();
    if (id.isEmpty) {
      setState(() {
        _error = 'Missing session';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _pollCount = 0;
    });

    try {
      await _api.postReportGenerate(id);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_pollOnce()),
      );
      await _pollOnce();
    } catch (e) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pollOnce() async {
    if (!mounted) return;
    final id = widget.sessionId.trim();
    _pollCount++;
    if (_pollCount > _maxPolls) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _error = 'Report generation timed out. Try again.';
          _loading = false;
        });
      }
      return;
    }

    try {
      final data = await _api.getReport(id);
      if (!mounted) return;
      if (data != null) {
        _pollTimer?.cancel();
        setState(() {
          _result = data;
          _loading = false;
          _error = null;
        });
        _gaugeCtrl.forward(from: 0);
      }
    } catch (e) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    final id = widget.sessionId.trim();
    if (id.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _api.postMeetingExportPdf(id);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: 'ava_executive_briefing.pdf',
            ),
          ],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF exported successfully'),
          backgroundColor: AvaColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AvaColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _replayNegotiation() {
    final q = briefingTabsQuery(
      widget.sessionId,
      widget.investorName,
      investorCompany: widget.investorCompany,
      investorCity: widget.investorCity,
      investorCountry: widget.investorCountry,
      userEquity: widget.userEquity,
      userValuation: widget.userValuation,
      meetingFormat: widget.meetingFormat,
    );
    context.go('/briefing/negotiation?$q');
  }

  static String _stripOuterQuotes(String s) {
    var t = s.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return BriefingGradientScaffold(
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(widget.investorName),
        onBack: () => goBriefingBack(
          context,
          5,
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
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();
    return _content(_result!);
  }

  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          avaAvatar(size: 52),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            color: AvaColors.gold,
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
          const Text(
            'Generating your briefing…',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              color: AvaColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Synthesizing all intelligence sections',
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
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: AvaText.caption,
            ),
            const SizedBox(height: 20),
            avaGoldBtn('Retry', () {
              _pollCount = 0;
              unawaited(_startReportFlow());
            }),
          ],
        ),
      ),
    );
  }

  Widget _content(ReportResult r) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottom),
      children: [
        _gaugeSection(r),
        const SizedBox(height: 14),
        _motivationalCard(_stripOuterQuotes(r.motivationalMessage)),
        const SizedBox(height: 14),
        Text(
          'INTELLIGENCE SECTIONS',
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 2.5,
            color: AvaColors.blue.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _sectionGrid(r),
        const SizedBox(height: 14),
        _verdictCard(_stripOuterQuotes(r.overallVerdict)),
        const SizedBox(height: 14),
        _actionButtons(),
      ],
    );
  }

  Widget _gaugeSection(ReportResult r) {
    return Column(
      children: [
        Text(
          'READINESS SCORE',
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 2.5,
            color: AvaColors.blue.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _gaugeAnim,
          builder: (context, _) {
            final t = _gaugeAnim.value;
            final arc = t * r.readinessScore / 100;
            final score = (r.readinessScore * t).round();
            return CustomPaint(
              size: const Size(200, 110),
              painter: _ReportGaugePainter(
                value: arc.clamp(0.0, 1.0),
                score: score,
                gaugeColor: r.gaugeColor,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: r.overallColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: r.overallColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            r.overallLabel(context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: r.overallColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _motivationalCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AvaColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avaAvatar(size: 26),
              const SizedBox(width: 9),
              const Text(
                'AVA · FINAL BRIEFING',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AvaColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AvaColors.text,
              height: 1.65,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionGrid(ReportResult r) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: _kSections.map((s) {
        final status = s.statusKey(r.sectionStatuses);
        final summary = s.summary(r);
        return _statusCard(
          emoji: s.emoji,
          name: s.name,
          summary: summary,
          status: status,
        );
      }).toList(),
    );
  }

  Widget _statusCard({
    required String emoji,
    required String name,
    required String summary,
    required String status,
  }) {
    final normalized = status.toLowerCase().trim();
    late final Color chipColor;
    late final String chipLabel;
    switch (normalized) {
      case 'strong':
        chipColor = AvaColors.green;
        chipLabel = 'Strong';
        break;
      case 'review':
        chipColor = AvaColors.amber;
        chipLabel = 'Review';
        break;
      default:
        chipColor = AvaColors.gold;
        chipLabel = 'Ready';
    }

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AvaColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 9,
              color: AvaColors.muted,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _verdictCard(String verdict) {
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
            'OVERALL VERDICT',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              color: AvaColors.blue.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verdict,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              color: AvaColors.text,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _exporting ? null : _exportPdf,
              borderRadius: BorderRadius.circular(13),
              child: Ink(
                height: 50,
                decoration: BoxDecoration(
                  color: _exporting ? AvaColors.border2 : AvaColors.gold,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AvaColors.muted,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AvaColors.bg,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Export PDF',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AvaColors.bg,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AvaColors.card,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: _replayNegotiation,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AvaColors.border2),
              ),
              child: const Icon(
                Icons.replay_rounded,
                color: AvaColors.muted,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportGaugePainter extends CustomPainter {
  _ReportGaugePainter({
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
    final r = size.width * 0.44;

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
        ..strokeWidth = 12
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
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: gaugeColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height - 4));
  }

  @override
  bool shouldRepaint(_ReportGaugePainter old) =>
      old.value != value || old.score != score || old.gaugeColor != gaugeColor;
}
