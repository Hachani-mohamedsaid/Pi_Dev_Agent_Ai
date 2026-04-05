import '../models/wellbeing_models.dart';
import 'wellbeing_questions.dart';

/// Maps unified stress score 0–100 to product band labels.
String wellbeingBandForScore(double score0to100) {
  final s = score0to100.clamp(0, 100);
  if (s < 22) return 'Balanced';
  if (s < 38) return 'Early Pressure';
  if (s < 58) return 'Structured Reset';
  if (s < 78) return 'Active Recovery';
  return 'Critical Intervention';
}

/// Trend vs previous assessment on the same 0–100 scale.
String wellbeingTrendLabel(double? previousScore0to100, double current0to100) {
  if (previousScore0to100 == null) return 'First Assessment';
  final d = current0to100 - previousScore0to100;
  if (d <= -20) return 'Recovering';
  if (d >= -10 && d <= 10) return 'Stable';
  if (d <= 20) return 'Deteriorating';
  return 'Accelerating Collapse';
}

WellbeingDominant _dominantFromAverages(double c, double e, double p) {
  if (c >= e && c >= p) return WellbeingDominant.cognitive;
  if (e >= p) return WellbeingDominant.emotional;
  return WellbeingDominant.physical;
}

String _signature(double c, double e, double p) {
  const high = 3.5;
  const low = 2.5;
  final hc = c >= high;
  final he = e >= high;
  final hp = p >= high;
  final lc = c < low;
  final le = e < low;
  final lp = p < low;

  if (hc && !he && !hp) {
    return 'High cognitive load with lighter pressure on emotional and physical channels.';
  }
  if (he && !hc && !hp) {
    return 'Emotional and social pressure leads; cognitive and physical are relatively contained.';
  }
  if (hp && !hc && !he) {
    return 'Physical depletion dominates; mental and emotional channels show more margin.';
  }
  if (hc && he && !hp) {
    return 'Combined cognitive and emotional strain with physical signals still secondary.';
  }
  if (lc && le && lp) {
    return 'Moderate load across dimensions without a single sharp spike.';
  }
  return 'Mixed profile across cognitive, emotional, and physical channels.';
}

/// Converts raw Likert 1–5 answers (Q1…Q9 order) into effective stress values then full diagnostic copy.
WellbeingDiagnostic computeWellbeingDiagnostic({
  required List<int> answers1to5,
  double? previousScore0to100,
}) {
  assert(answers1to5.length == kWellbeingQuestions.length);

  final effective = <int>[];
  for (var i = 0; i < kWellbeingQuestions.length; i++) {
    final a = answers1to5[i].clamp(1, 5);
    final q = kWellbeingQuestions[i];
    effective.add(q.reverseScore ? (6 - a) : a);
  }

  final sum = effective.fold<int>(0, (s, v) => s + v);
  const minSum = 9;
  const maxSum = 45;
  final raw01 = (sum - minSum) / (maxSum - minSum);
  final score100 = (raw01 * 100).clamp(0.0, 100.0).toDouble();
  final scoreInt = score100.round();

  final c = (effective[0] + effective[1] + effective[2]) / 3.0;
  final em = (effective[3] + effective[4] + effective[5]) / 3.0;
  final ph = (effective[6] + effective[7] + effective[8]) / 3.0;

  final dominant = _dominantFromAverages(c, em, ph);
  final band = wellbeingBandForScore(score100);
  final trend = wellbeingTrendLabel(previousScore0to100, score100);
  final signature = _signature(c, em, ph);

  final dominantLabel = switch (dominant) {
    WellbeingDominant.cognitive => 'COGNITIVE',
    WellbeingDominant.emotional => 'EMOTIONAL',
    WellbeingDominant.physical => 'PHYSICAL',
  };

  final reveal =
      'Your stress score of $scoreInt/100 indicates $band. Your dominant stress type is $dominantLabel, which is common among entrepreneurs. '
      'This suggests ${_revealSuffix(dominant, band)}';

  final risk = _riskParagraph(dominant, band);
  final protocol = _protocolBullets(dominant, band);
  final roadmap = _roadmapWeeks(dominant);
  const quote =
      'One retreat chosen well beats years of running on empty.';

  return WellbeingDiagnostic(
    stressScore0to100: scoreInt,
    bandLabel: band,
    dominant: dominant,
    cognitiveAvg: double.parse(c.toStringAsFixed(2)),
    emotionalAvg: double.parse(em.toStringAsFixed(2)),
    physicalAvg: double.parse(ph.toStringAsFixed(2)),
    trendLabel: trend,
    stressSignature: signature,
    revealParagraph: reveal,
    hiddenRiskParagraph: risk,
    protocolBullets: protocol,
    roadmapWeeks: roadmap,
    closingQuote: quote,
  );
}

String _revealSuffix(WellbeingDominant d, String band) {
  final focus = switch (d) {
    WellbeingDominant.cognitive => 'decision load and mental rumination are central themes.',
    WellbeingDominant.emotional =>
      'isolation, guilt, or financial worry may be taking a quiet toll.',
    WellbeingDominant.physical =>
      'your body may be signalling limits even when your mind pushes forward.',
  };
  if (band == 'Balanced' || band == 'Early Pressure') {
    return 'you still have room to course-correct before patterns harden. $focus';
  }
  return 'you are carrying meaningful strain. $focus';
}

String _riskParagraph(WellbeingDominant d, String band) {
  if (band == 'Balanced') {
    return 'Even balanced seasons benefit from one honest monthly checkpoint so drift is caught early.';
  }
  final core = switch (d) {
    WellbeingDominant.cognitive =>
      'Unmanaged cognitive overload erodes decision quality and can amplify every other stress channel.',
    WellbeingDominant.emotional =>
      'Unaddressed emotional pressure often compounds into burnout narratives and strained relationships.',
    WellbeingDominant.physical =>
      'Unmanaged physical stress can lead to decreased decision quality and potential health impacts. Early intervention helps maintain performance and prevents escalation.',
  };
  return core;
}

List<String> _protocolBullets(WellbeingDominant d, String band) {
  final base = <String>[
    'Optional short recovery window (walk, spa, ocean); prioritize sleep and one nourishing meal daily.',
    'One digital curfew before bed; protect one non-negotiable rest block weekly.',
  ];
  switch (d) {
    case WellbeingDominant.cognitive:
      base.insert(
        0,
        'Batch decisions where possible; end each day with a 5-minute “close the loop” list.',
      );
      break;
    case WellbeingDominant.emotional:
      base.insert(
        0,
        'Name one trusted peer or mentor check-in weekly; schedule guilt-free rest as a calendar event.',
      );
      break;
    case WellbeingDominant.physical:
      base.insert(0, 'Weekly yoga or movement; reduce stimulant reliance on one half-day per week.');
      break;
  }
  if (band == 'Active Recovery' || band == 'Critical Intervention') {
    base.add('Consider professional support if symptoms persist or worsen.');
  }
  return base;
}

List<String> _roadmapWeeks(WellbeingDominant d) {
  return [
    'Week 1: Prioritise one early night and one real meal per day.',
    'Week 2: Add two movement or body sessions; keep one digital curfew.',
    'Week 3: Block one full rest day; optional half-day recovery outing.',
    'Week 4: Optional short recovery stay if your band remains elevated.',
  ];
}
