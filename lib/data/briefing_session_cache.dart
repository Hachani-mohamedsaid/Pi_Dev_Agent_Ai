import 'models/culture_briefing_model.dart';

/// In-memory cache: skip POST /meetings/:id/briefing/culture if already loaded for this meeting.
class BriefingSessionCache {
  BriefingSessionCache._();
  static final BriefingSessionCache instance = BriefingSessionCache._();

  final Map<String, CultureBriefingModel> _culture = {};

  CultureBriefingModel? cultureFor(String meetingId) => _culture[meetingId];

  void setCulture(String meetingId, CultureBriefingModel data) {
    _culture[meetingId] = data;
  }

  void clearCulture(String meetingId) => _culture.remove(meetingId);
}
