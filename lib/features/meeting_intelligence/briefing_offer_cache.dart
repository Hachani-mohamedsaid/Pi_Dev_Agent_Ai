import 'models/offer_result.dart';

/// Cache for offer briefing (one POST per session).
class BriefingOfferCache {
  BriefingOfferCache._();

  static final Map<String, OfferResult> _map = {};

  static OfferResult? get(String sessionId) {
    final k = sessionId.trim();
    if (k.isEmpty) return null;
    return _map[k];
  }

  static void put(String sessionId, OfferResult result) {
    final k = sessionId.trim();
    if (k.isEmpty) return;
    _map[k] = result;
  }
}
