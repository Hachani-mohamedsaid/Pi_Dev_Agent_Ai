import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/wellbeing_api_client.dart';
import '../data/wellbeing_nest_mapper.dart';
import '../data/wellbeing_questions.dart';
import '../data/wellbeing_registration.dart';
import '../data/wellbeing_scoring.dart';
import '../data/wellbeing_storage.dart';
import '../data/wellbeing_submit_outcome.dart';
import '../models/wellbeing_models.dart';
import '../wellbeing_section_styles.dart';

/// 9 Likert questions (sections A/B/C); submits to optional API + local engine.
class WellbeingQuestionnaireScreen extends StatefulWidget {
  const WellbeingQuestionnaireScreen({super.key});

  @override
  State<WellbeingQuestionnaireScreen> createState() =>
      _WellbeingQuestionnaireScreenState();
}

class _WellbeingQuestionnaireScreenState
    extends State<WellbeingQuestionnaireScreen> {
  final _api = WellbeingApiClient();
  late List<int?> _answers;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(kWellbeingQuestions.length, null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enforceGate());
  }

  Future<void> _enforceGate() async {
    await ensureWellbeingIdentity(_api);

    var allowed = true;
    if (_api.isConfigured) {
      var uid = await WellbeingStorage.userId();
      if (uid != null && uid.isNotEmpty) {
        var st = await _api.fetchStatus(uid);
        if (st?.userNotFound == true) {
          await WellbeingStorage.clearWellbeingIdentity();
          await ensureWellbeingIdentity(_api);
          uid = await WellbeingStorage.userId();
          if (uid != null && uid.isNotEmpty) {
            st = await _api.fetchStatus(uid);
          }
        }
        if (st != null && !st.userNotFound) {
          allowed = st.allowed;
        } else {
          allowed = await WellbeingStorage.localMonthlyAllowed();
        }
      } else {
        allowed = await WellbeingStorage.localMonthlyAllowed();
      }
    } else {
      allowed = await WellbeingStorage.localMonthlyAllowed();
    }

    if (!mounted || allowed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in not available for this cycle.'),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/wellbeing');
    }
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  int get _answeredCount => _answers.whereType<int>().length;

  Future<void> _analyze() async {
    if (_answeredCount < kWellbeingQuestions.length || _submitting) return;

    setState(() => _submitting = true);
    final values = _answers.map((e) => e!).toList();
    final prev = await WellbeingStorage.lastScore0to100();

    var diagnostic = computeWellbeingDiagnostic(
      answers1to5: values,
      previousScore0to100: prev,
    );

    String? aiHtml;
    var usedApi = false;
    final uid = await WellbeingStorage.userId();

    if (_api.isConfigured) {
      final outcome = await _api.submitWellbeing(
        answers: values,
        userId: uid,
        previousScore: prev,
      );
      if (outcome is WellbeingSubmitDenied) {
        if (!mounted) return;
        setState(() => _submitting = false);
        final extra = outcome.nextAvailableIso;
        final msg = extra != null && extra.isNotEmpty
            ? '${outcome.message} — next: $extra'
            : outcome.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      if (outcome is WellbeingSubmitSuccess) {
        usedApi = true;
        final data = outcome.data;
        aiHtml =
            data['aiResponse']?.toString() ??
            data['ai_response']?.toString();
        final scoresRaw = data['scores'];
        if (scoresRaw is Map) {
          diagnostic = mergeDiagnosticWithNestScores(
            Map<String, dynamic>.from(scoresRaw),
            diagnostic,
          );
        }
      }
    }

    await WellbeingStorage.setLastScore(diagnostic.stressScore0to100.toDouble());
    await WellbeingStorage.setLastSubmitYyyymm(
      DateTime.now().year * 100 + DateTime.now().month,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final outcome = WellbeingSessionOutcome(
      diagnostic: diagnostic,
      aiHtmlFromServer: aiHtml,
      usedRemoteApi: usedApi,
    );
    context.push('/wellbeing/results', extra: outcome);
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0D1B2A);
    final hPad = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
        leadingWidth: 52,
        titleSpacing: 12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.cyan400,
          iconSize: 20,
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/wellbeing');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MONTHLY DIAGNOSTIC',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: AppColors.cyan400.withValues(alpha: 0.95),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rate your experience',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: _scaleLegendRow(),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
              children: [
                for (final section in kWellbeingSections) ...[
                  _sectionHeader(section),
                  const SizedBox(height: 12),
                  ...kWellbeingQuestions
                      .where((q) => q.sectionId == section.id)
                      .map(_questionCard),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              hPad,
              12,
              hPad,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(
                  color: AppColors.cyan500.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Answered: $_answeredCount / ${kWellbeingQuestions.length}',
                  style: const TextStyle(
                    color: AppColors.cyan400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _answeredCount == kWellbeingQuestions.length
                          ? AppColors.buttonGradient
                          : null,
                      color: _answeredCount == kWellbeingQuestions.length
                          ? null
                          : Colors.white12,
                      boxShadow: _answeredCount == kWellbeingQuestions.length
                          ? [
                              BoxShadow(
                                color: AppColors.cyan500.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _answeredCount == kWellbeingQuestions.length &&
                                !_submitting
                            ? _analyze
                            : null,
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'ANALYSE MY RESULTS  →',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: _answeredCount ==
                                            kWellbeingQuestions.length
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _scaleChipData = <({int v, String short, Color a, Color b})>[
    (v: 1, short: 'Never', a: Color(0xFF1E3A5F), b: Color(0xFF2563EB)),
    (v: 2, short: 'Rarely', a: Color(0xFF1D4ED8), b: Color(0xFF38BDF8)),
    (v: 3, short: 'Some', a: Color(0xFF0369A1), b: Color(0xFF22D3EE)),
    (v: 4, short: 'Often', a: Color(0xFF0891B2), b: Color(0xFF67E8F9)),
    (v: 5, short: 'Always', a: Color(0xFF0E7490), b: Color(0xFFA5F3FC)),
  ];

  Widget _scaleLegendRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap a number for each question',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.cyan400.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final e in _scaleChipData) ...[
              Expanded(
                child: _scaleLegendChip(e.v, e.short, e.a, e.b),
              ),
              if (e.v < 5) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  Widget _scaleLegendChip(int value, String short, Color a, Color b) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a, b],
        ),
        boxShadow: [
          BoxShadow(
            color: b.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(WellbeingSection s) {
    final style = WellbeingSectionStyle.forSectionId(s.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.headerGradient,
        border: Border.all(
          color: style.bright.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: style.likertSelectedGradient,
              boxShadow: [
                BoxShadow(
                  color: style.glow.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              s.id,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 17,
                      tablet: 19,
                      desktop: 20,
                    ),
                    height: 1.15,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.subtitle,
                  style: TextStyle(
                    color: style.bright.withValues(alpha: 0.95),
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

  Widget _questionCard(WellbeingQuestion q) {
    final idx = q.index - 1;
    final selected = _answers[idx];
    final style = WellbeingSectionStyle.forSectionId(q.sectionId);
    const bg = Color(0xFF0D1B2A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: style.cardBorderGradient,
          boxShadow: [
            BoxShadow(
              color: style.glow.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.5),
            color: Color.lerp(bg, style.surfaceTint, 0.42),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          style.primary.withValues(alpha: 0.35),
                          style.soft.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: style.bright.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      'Q${q.index} · ${q.sectionId}',
                      style: TextStyle(
                        color: style.bright,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                q.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (i) {
                  final v = i + 1;
                  final on = selected == v;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _answers[idx] = v),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: on ? style.likertSelectedGradient : null,
                              border: Border.all(
                                color: on
                                    ? style.bright
                                    : style.primary.withValues(alpha: 0.5),
                                width: on ? 2 : 1.5,
                              ),
                              color: on
                                  ? null
                                  : style.primary.withValues(alpha: 0.08),
                              boxShadow: on
                                  ? [
                                      BoxShadow(
                                        color: style.glow.withValues(
                                          alpha: 0.55,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '$v',
                              style: TextStyle(
                                color: on
                                    ? Colors.white
                                    : style.bright.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Never',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.bright.withValues(alpha: 0.65),
                    ),
                  ),
                  Text(
                    'Always',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.bright.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
