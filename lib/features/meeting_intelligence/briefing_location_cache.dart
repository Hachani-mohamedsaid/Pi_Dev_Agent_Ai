import 'models/location_result.dart';

/// Cache for location briefing (one POST per session).
class BriefingLocationCache {
  BriefingLocationCache._();

  static final Map<String, LocationResult> _map = {};

  static LocationResult? get(String sessionId) {
    final k = sessionId.trim();
    if (k.isEmpty) return null;
    return _map[k];
  }

  static void put(String sessionId, LocationResult result) {
    final k = sessionId.trim();
    if (k.isEmpty) return;
    _map[k] = result;
  }
}
