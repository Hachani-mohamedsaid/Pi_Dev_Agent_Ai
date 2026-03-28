/// POST /meetings/:id/simulation/start
class SimulationStartResult {
  const SimulationStartResult({required this.openingLine});

  final String openingLine;

  factory SimulationStartResult.fromJson(Map<String, dynamic> j) =>
      SimulationStartResult(
        openingLine:
            j['openingLine']?.toString() ?? j['opening_line']?.toString() ?? '',
      );
}

/// POST /meetings/:id/simulation/turn
class NegotiationTurnResult {
  const NegotiationTurnResult({
    required this.investorReply,
    required this.confidenceScore,
    required this.logicScore,
    required this.emotionalControlScore,
    required this.feedback,
    required this.color,
    required this.suggestedImprovement,
  });

  final String investorReply;
  final int confidenceScore;
  final int logicScore;
  final int emotionalControlScore;
  final String feedback;

  /// `green` | `amber` | `red` — drives feedback UI only; not derived from scores on the client.
  final String color;
  final String suggestedImprovement;

  factory NegotiationTurnResult.fromJson(Map<String, dynamic> j) =>
      NegotiationTurnResult(
        investorReply: _pickStr(j, const [
          'investorReply',
          'investor_reply',
        ]),
        confidenceScore: _pickIntMulti(j, const [
          'confidence_score',
          'confidenceScore',
        ]),
        logicScore: _pickIntMulti(j, const [
          'logic_score',
          'logicScore',
        ]),
        emotionalControlScore: _pickIntMulti(j, const [
          'emotional_control_score',
          'emotionalControlScore',
        ]),
        feedback: _pickStr(j, const [
          'feedback',
          'observation',
          'coach_observation',
        ]),
        color: (j['color']?.toString() ?? 'amber').toLowerCase(),
        suggestedImprovement: _pickStr(j, const [
          'suggested_improvement',
          'suggestedImprovement',
        ]),
      );
}

/// POST /meetings/:id/simulation/end
class SimulationEndResult {
  const SimulationEndResult({required this.averageScore});

  final double averageScore;

  factory SimulationEndResult.fromJson(Map<String, dynamic> j) {
    final raw = j['averageScore'] ?? j['average_score'];
    return SimulationEndResult(
      averageScore: _toDouble(raw),
    );
  }
}

String _pickStr(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v != null) return v.toString();
  }
  return '';
}

int _pickIntMulti(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is int) return v;
    if (v is num) return v.round();
    final p = int.tryParse(v.toString());
    if (p != null) return p;
  }
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
