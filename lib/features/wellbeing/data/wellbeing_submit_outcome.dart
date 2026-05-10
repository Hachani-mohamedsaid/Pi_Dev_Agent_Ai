/// Résultat de `POST /api/wellbeing` (Nest).
sealed class WellbeingSubmitOutcome {
  const WellbeingSubmitOutcome();

  bool get isSuccess => this is WellbeingSubmitSuccess;
}

class WellbeingSubmitSuccess extends WellbeingSubmitOutcome {
  const WellbeingSubmitSuccess(this.data);

  final Map<String, dynamic> data;
}

class WellbeingSubmitDenied extends WellbeingSubmitOutcome {
  const WellbeingSubmitDenied({required this.message, this.nextAvailableIso});

  final String message;
  final String? nextAvailableIso;
}

/// Réseau / parsing / 5xx — l’app peut tomber sur le moteur local seul.
class WellbeingSubmitFailed extends WellbeingSubmitOutcome {
  const WellbeingSubmitFailed();
}
