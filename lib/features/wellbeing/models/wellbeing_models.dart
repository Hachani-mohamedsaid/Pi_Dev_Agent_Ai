import 'package:flutter/foundation.dart';

/// Dominant stress channel (highest of the three dimension averages).
enum WellbeingDominant { cognitive, emotional, physical }

/// Outcome after submitting the 9-item diagnostic (local engine ± optional API).
@immutable
class WellbeingSessionOutcome {
  const WellbeingSessionOutcome({
    required this.diagnostic,
    this.aiHtmlFromServer,
    this.usedRemoteApi = false,
  });

  final WellbeingDiagnostic diagnostic;
  final String? aiHtmlFromServer;
  final bool usedRemoteApi;
}

@immutable
class WellbeingDiagnostic {
  const WellbeingDiagnostic({
    required this.stressScore0to100,
    required this.bandLabel,
    required this.dominant,
    required this.cognitiveAvg,
    required this.emotionalAvg,
    required this.physicalAvg,
    required this.trendLabel,
    required this.stressSignature,
    required this.revealParagraph,
    required this.hiddenRiskParagraph,
    required this.protocolBullets,
    required this.roadmapWeeks,
    required this.closingQuote,
  });

  final int stressScore0to100;
  final String bandLabel;
  final WellbeingDominant dominant;
  final double cognitiveAvg;
  final double emotionalAvg;
  final double physicalAvg;
  final String trendLabel;
  final String stressSignature;
  final String revealParagraph;
  final String hiddenRiskParagraph;
  final List<String> protocolBullets;
  final List<String> roadmapWeeks;
  final String closingQuote;

  String get dominantDisplay => switch (dominant) {
        WellbeingDominant.cognitive => 'COGNITIVE',
        WellbeingDominant.emotional => 'EMOTIONAL',
        WellbeingDominant.physical => 'PHYSICAL',
      };
}

/// Remote gate (FastAPI) when [WellbeingApiClient] is configured.
@immutable
class WellbeingRemoteStatus {
  const WellbeingRemoteStatus({
    required this.allowed,
    this.nextAvailableDate,
    this.raw,
    this.userNotFound = false,
  });

  final bool allowed;
  final DateTime? nextAvailableDate;
  final Map<String, dynamic>? raw;

  /// Nest renvoie 404 si `user_id` inconnu → ré-enregistrer l’utilisateur wellbeing.
  final bool userNotFound;
}
