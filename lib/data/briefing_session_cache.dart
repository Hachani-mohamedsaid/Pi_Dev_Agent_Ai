import '../features/meeting_intelligence/models/cultural_result.dart';

/// In-memory cache: skip POST /meetings/:id/briefing/culture if already loaded for this meeting.
class BriefingSessionCache {
  BriefingSessionCache._();
  static final BriefingSessionCache instance = BriefingSessionCache._();

  final Map<String, CulturalResult> _culture = {};

  CulturalResult? cultureFor(String meetingId) => _culture[meetingId];

  void setCulture(String meetingId, CulturalResult data) {
    _culture[meetingId] = data;
  }

  void clearCulture(String meetingId) => _culture.remove(meetingId);
}
