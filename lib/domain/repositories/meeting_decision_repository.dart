import '../entities/meeting_decision.dart';

abstract class MeetingDecisionRepository {
  Future<MeetingDecision> submitMeetingDecision({
    required DateTime meetingDate,
    required DateTime meetingTime,
    required String decision,
    required int durationMinutes,
    required String token,
  });
}
