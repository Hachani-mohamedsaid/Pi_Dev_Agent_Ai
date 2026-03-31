import 'models/cultural_result.dart';

/// In-memory cache for cultural briefing per meeting session (skip POST on revisit).
class BriefingCultureCache {
  BriefingCultureCache._();

  static final Map<String, CulturalResult> _map = {};

  static CulturalResult? get(String sessionId) {
    final k = sessionId.trim();
    if (k.isEmpty) return null;
    return _map[k];
  }

  static void put(String sessionId, CulturalResult result) {
    final k = sessionId.trim();
    if (k.isEmpty) return;
    _map[k] = result;
  }

  static void clear(String sessionId) => _map.remove(sessionId.trim());
}
