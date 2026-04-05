import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../models/wellbeing_models.dart';
import '../wellbeing_section_styles.dart';

/// Stress summary + deterministic narrative; optional server HTML as extra text.
class WellbeingResultsScreen extends StatelessWidget {
  const WellbeingResultsScreen({super.key, required this.outcome});

  final WellbeingSessionOutcome outcome;

  static Color _accentForBand(String band) {
    switch (band) {
      case 'Balanced':
        return const Color(0xFF22C55E);
      case 'Early Pressure':
        return const Color(0xFF38BDF8);
      case 'Structured Reset':
        return const Color(0xFFF59E0B);
      case 'Active Recovery':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFEF4444);
    }
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// First sentence highlighted for quick scanning.
  static (String lead, String rest) _leadRest(String paragraph) {
    final t = paragraph.trim();
    final i = t.indexOf('. ');
    if (i <= 0) return (t, '');
    return (t.substring(0, i + 1), t.substring(i + 2).trim());
  }

  static String _encouragementLine(WellbeingDiagnostic d) {
    switch (d.bandLabel) {
      case 'Balanced':
        return 'Strong baseline — small habits will keep you there.';
      case 'Early Pressure':
        return 'You caught this early. Small resets compound fast.';
      case 'Structured Reset':
        return 'Structure is your friend this month — one layer at a time.';
      case 'Active Recovery':
        return 'Recovery is productive work. You are allowed to slow down.';
      default:
        return 'Showing up for this check-in is already a win.';
    }
  }

  String _fullReportText() {
    final d = outcome.diagnostic;
    final buf = StringBuffer()
      ..writeln('AVA Wellbeing — ${d.stressScore0to100}/100 (${d.bandLabel})')
      ..writeln('Dominant: ${d.dominantDisplay}')
      ..writeln(
        'Dimensions — Cognitive ${d.cognitiveAvg}/5 · Emotional ${d.emotionalAvg}/5 · Physical ${d.physicalAvg}/5',
      )
      ..writeln('Trend: ${d.trendLabel}')
      ..writeln()
      ..writeln(d.revealParagraph)
      ..writeln()
      ..writeln(d.hiddenRiskParagraph)
      ..writeln()
      ..writeln('Recovery protocol:')
      ..writeln(d.protocolBullets.map((e) => '• $e').join('\n'))
      ..writeln()
      ..writeln('4-week roadmap:')
      ..writeln(d.roadmapWeeks.join('\n'))
      ..writeln()
      ..writeln(d.closingQuote);
    final extra = outcome.aiHtmlFromServer;
    if (extra != null && extra.trim().isNotEmpty) {
      buf
        ..writeln()
        ..writeln('---')
        ..writeln(_stripHtml(extra));
    }
    return buf.toString();
  }

  Future<void> _share(BuildContext context) async {
    final text = _fullReportText();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }

  void _retake(BuildContext context) {
    context.go('/wellbeing/check-in');
  }

  Widget _glowShell({
    required Color accent,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.42),
            AppColors.cyan500.withValues(alpha: 0.06),
            const Color(0xFF0D1B2A),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1C2C),
          borderRadius: BorderRadius.circular(20.5),
        ),
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = outcome.diagnostic;
    final accent = _accentForBand(d.bandLabel);
    final pad = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
    final aiPlain = outcome.aiHtmlFromServer != null
        ? _stripHtml(outcome.aiHtmlFromServer!)
        : null;

    final reveal = _leadRest(d.revealParagraph);
    final risk = _leadRest(d.hiddenRiskParagraph);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AVA',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.cyan400,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.cyan400,
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, 8, pad, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _scoreCard(context, d, accent)
                .animate()
                .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.07,
                  duration: 450.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 16),
            _encouragementBanner(accent, d)
                .animate()
                .fadeIn(delay: 80.ms, duration: 450.ms)
                .slideY(
                  begin: 0.06,
                  delay: 80.ms,
                  duration: 450.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 14),
            _agentHeader()
                .animate()
                .fadeIn(delay: 140.ms, duration: 400.ms),
            const SizedBox(height: 14),
            _insightCard(
              title: 'What your results reveal',
              icon: Icons.visibility_rounded,
              accent: AppColors.cyan400,
              lead: reveal.$1,
              rest: reveal.$2,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 420.ms)
                .slideX(
                  begin: 0.04,
                  delay: 200.ms,
                  duration: 420.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 12),
            _insightCard(
              title: 'The hidden risk',
              icon: Icons.warning_amber_rounded,
              accent: const Color(0xFFFBBF24),
              lead: risk.$1,
              rest: risk.$2,
            )
                .animate()
                .fadeIn(delay: 260.ms, duration: 420.ms)
                .slideX(
                  begin: 0.04,
                  delay: 260.ms,
                  duration: 420.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 12),
            _protocolCard(d)
                .animate()
                .fadeIn(delay: 320.ms, duration: 420.ms),
            const SizedBox(height: 12),
            _roadmapCard(d)
                .animate()
                .fadeIn(delay: 380.ms, duration: 420.ms),
            const SizedBox(height: 14),
            _quoteEncouragementCard(d, accent)
                .animate()
                .fadeIn(delay: 440.ms, duration: 500.ms)
                .scale(
                  begin: const Offset(0.96, 0.96),
                  delay: 440.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
            if (aiPlain != null && aiPlain.isNotEmpty) ...[
              const SizedBox(height: 16),
              _serverNarrativeCard(aiPlain)
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _retake(context),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan400,
                      side: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Save / Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan400,
                      side: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _encouragementBanner(Color accent, WellbeingDiagnostic d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.28),
            WellbeingSectionStyle.cognitive.primary.withValues(alpha: 0.12),
            AppColors.cyan500.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: accent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _encouragementLine(d),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use the cards below as your playbook — focus on one move this week.',
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: 900.ms,
          duration: 2200.ms,
          color: accent.withValues(alpha: 0.12),
        );
  }

  Widget _agentHeader() {
    return _glowShell(
      accent: AppColors.cyan400,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan400.withValues(alpha: 0.35),
                  AppColors.cyan500.withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(
                color: AppColors.cyan400.withValues(alpha: 0.5),
              ),
            ),
            child: const Text('🧠', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVA Wellbeing Agent',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Entrepreneur Psychological Specialist',
                  style: TextStyle(
                    color: AppColors.cyan400,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard({
    required String title,
    required IconData icon,
    required Color accent,
    required String lead,
    required String rest,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF131F30),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      rest,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _protocolCard(WellbeingDiagnostic d) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WellbeingSectionStyle.physical.glow.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: WellbeingSectionStyle.physical.glow.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: WellbeingSectionStyle.physical.surfaceTint.withValues(
                alpha: 0.5,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.healing_rounded,
                    color: WellbeingSectionStyle.physical.bright,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'YOUR RECOVERY PROTOCOL',
                    style: TextStyle(
                      color: WellbeingSectionStyle.physical.bright,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (var i = 0; i < d.protocolBullets.length; i++) ...[
                    _protocolBulletRow(d.protocolBullets[i], i),
                    if (i < d.protocolBullets.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _protocolBulletRow(String text, int index) {
    final g = WellbeingSectionStyle.physical.glow;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF121C28),
        border: Border(
          left: BorderSide(color: g, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: g.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: g.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: g,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.45,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * index),
          duration: 350.ms,
        )
        .slideX(
          begin: 0.03,
          delay: Duration(milliseconds: 40 * index),
          duration: 350.ms,
        );
  }

  Widget _roadmapCard(WellbeingDiagnostic d) {
    final c = AppColors.cyan400;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
        color: const Color(0xFF121C28),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: c, size: 22),
              const SizedBox(width: 10),
              Text(
                'YOUR 4-WEEK ROADMAP',
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...d.roadmapWeeks.asMap().entries.map((e) {
            final isFirst = e.key == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFirst ? c : c.withValues(alpha: 0.35),
                          boxShadow: isFirst
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      if (e.key < d.roadmapWeeks.length - 1)
                        Container(
                          width: 2,
                          height: 36,
                          margin: const EdgeInsets.only(top: 4),
                          color: c.withValues(alpha: 0.2),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isFirst ? c : Colors.white70,
                        height: 1.45,
                        fontSize: 14,
                        fontWeight:
                            isFirst ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _quoteEncouragementCard(WellbeingDiagnostic d, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WellbeingSectionStyle.emotional.primary.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.2),
            AppColors.cyan500.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: WellbeingSectionStyle.emotional.bright.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: WellbeingSectionStyle.emotional.glow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: WellbeingSectionStyle.emotional.bright,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'KEEP GOING',
                style: TextStyle(
                  color: WellbeingSectionStyle.emotional.bright,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${d.closingQuote}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serverNarrativeCard(String plain) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121C28),
        border: Border.all(
          color: AppColors.cyan500.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NARRATIVE (SERVER)',
            style: TextStyle(
              color: AppColors.cyan400.withValues(alpha: 0.9),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            plain,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(
    BuildContext context,
    WellbeingDiagnostic d,
    Color accent,
  ) {
    return _glowShell(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STRESS SCORE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppColors.textCyan200.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.stressScore0to100}/100',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 38,
                          tablet: 42,
                          desktop: 46,
                        ),
                        fontWeight: FontWeight.w900,
                        color: accent,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.blur_circular, size: 44, color: accent),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 120,
                    child: Text(
                      d.bandLabel.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'DOMINANT: ${d.dominantDisplay}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Trend: ${d.trendLabel}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textCyan200.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          _dimRow(
            context,
            'COGNITIVE',
            d.cognitiveAvg,
            d.dominant == WellbeingDominant.cognitive,
            WellbeingSectionStyle.cognitive,
          ),
          const SizedBox(height: 12),
          _dimRow(
            context,
            'EMOTIONAL',
            d.emotionalAvg,
            d.dominant == WellbeingDominant.emotional,
            WellbeingSectionStyle.emotional,
          ),
          const SizedBox(height: 12),
          _dimRow(
            context,
            'PHYSICAL',
            d.physicalAvg,
            d.dominant == WellbeingDominant.physical,
            WellbeingSectionStyle.physical,
          ),
        ],
      ),
    );
  }

  Widget _dimRow(
    BuildContext context,
    String label,
    double avg,
    bool star,
    WellbeingSectionStyle section,
  ) {
    final t = (avg / 5).clamp(0.0, 1.0);
    final barColor = star ? section.bright : section.primary.withValues(alpha: 0.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (star) ...[
              Icon(Icons.star_rounded, size: 16, color: section.bright),
              const SizedBox(width: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: section.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: section.bright.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: section.bright,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${avg.toStringAsFixed(1)}/5',
              style: TextStyle(
                color: star ? section.bright : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: t,
            minHeight: 8,
            backgroundColor: Colors.white10,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
