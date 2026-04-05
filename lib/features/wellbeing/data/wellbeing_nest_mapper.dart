import '../models/wellbeing_models.dart';

/// Fusionne les scores renvoyés par Nest (`computeDiagnostic`) avec le récit déjà calculé en local.
WellbeingDiagnostic mergeDiagnosticWithNestScores(
  Map<String, dynamic> scores,
  WellbeingDiagnostic local,
) {
  final stress =
      (scores['stressScore'] as num?)?.round() ?? local.stressScore0to100;
  final levelRaw =
      scores['level']?.toString().trim().isNotEmpty == true
          ? scores['level'].toString()
          : local.bandLabel;
  final dom = _parseDominant(
    scores['dominant']?.toString(),
    local.dominant,
  );
  final cog =
      (scores['cogAvg'] as num?)?.toDouble() ?? local.cognitiveAvg;
  final emo =
      (scores['emoAvg'] as num?)?.toDouble() ?? local.emotionalAvg;
  final phy =
      (scores['phyAvg'] as num?)?.toDouble() ?? local.physicalAvg;
  final trend =
      scores['trend']?.toString().trim().isNotEmpty == true
          ? scores['trend'].toString()
          : local.trendLabel;
  final signature =
      scores['signature']?.toString().trim().isNotEmpty == true
          ? scores['signature'].toString()
          : local.stressSignature;

  final band = _titleCaseBand(levelRaw);
  final domLabel = switch (dom) {
    WellbeingDominant.cognitive => 'COGNITIVE',
    WellbeingDominant.emotional => 'EMOTIONAL',
    WellbeingDominant.physical => 'PHYSICAL',
  };

  return WellbeingDiagnostic(
    stressScore0to100: stress,
    bandLabel: band,
    dominant: dom,
    cognitiveAvg: cog,
    emotionalAvg: emo,
    physicalAvg: phy,
    trendLabel: trend,
    stressSignature: signature,
    revealParagraph:
        'Your stress score of $stress/100 indicates $band. Your dominant stress type is $domLabel, which is common among entrepreneurs. '
        'Trend: $trend.',
    hiddenRiskParagraph: local.hiddenRiskParagraph,
    protocolBullets: local.protocolBullets,
    roadmapWeeks: local.roadmapWeeks,
    closingQuote: local.closingQuote,
  );
}

WellbeingDominant _parseDominant(String? raw, WellbeingDominant fallback) {
  switch ((raw ?? '').toUpperCase()) {
    case 'COGNITIVE':
      return WellbeingDominant.cognitive;
    case 'EMOTIONAL':
      return WellbeingDominant.emotional;
    case 'PHYSICAL':
      return WellbeingDominant.physical;
    default:
      return fallback;
  }
}

String _titleCaseBand(String level) {
  return level
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map(
        (w) =>
            w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}',
      )
      .join(' ');
}
