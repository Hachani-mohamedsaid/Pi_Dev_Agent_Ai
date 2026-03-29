/// Stores simulation [averageScore] per meeting id for the readiness / report screen.
class MeetingSimulationCache {
  MeetingSimulationCache._();

  static final Map<String, double> _averageBySession = {};

  static double? getAverageScore(String sessionId) {
    final k = sessionId.trim();
    if (k.isEmpty) return null;
    return _averageBySession[k];
  }

  static void putAverageScore(String sessionId, double averageScore) {
    final k = sessionId.trim();
    if (k.isEmpty) return;
    _averageBySession[k] = averageScore;
  }
}
