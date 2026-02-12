import '../entities/meeting_decision.dart';
import '../repositories/meeting_decision_repository.dart';

class SubmitMeetingDecisionUseCase {
  final MeetingDecisionRepository repository;

  SubmitMeetingDecisionUseCase(this.repository);

  Future<MeetingDecision> call({
    required DateTime meetingDate,
    required DateTime meetingTime,
    required String decision,
    required int durationMinutes,
    required String token,
  }) {
    return repository.submitMeetingDecision(
      meetingDate: meetingDate,
      meetingTime: meetingTime,
      decision: decision,
      durationMinutes: durationMinutes,
      token: token,
    );
  }
}
