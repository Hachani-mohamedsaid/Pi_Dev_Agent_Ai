import 'models/psych_result.dart';

/// Cache for psych briefing (same session = no second POST).
class BriefingPsychCache {
  BriefingPsychCache._();

  static final Map<String, PsychResult> _map = {};

  static PsychResult? get(String sessionId) {
    final k = sessionId.trim();
    if (k.isEmpty) return null;
    return _map[k];
  }

  static void put(String sessionId, PsychResult result) {
    final k = sessionId.trim();
    if (k.isEmpty) return;
    _map[k] = result;
  }
}
