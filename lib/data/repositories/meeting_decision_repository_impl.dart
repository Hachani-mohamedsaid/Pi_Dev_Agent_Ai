import '../datasources/meeting_decision_remote_data_source.dart';
import '../../domain/entities/meeting_decision.dart';
import '../../domain/repositories/meeting_decision_repository.dart';

class MeetingDecisionRepositoryImpl implements MeetingDecisionRepository {
  final MeetingDecisionRemoteDataSource remoteDataSource;

  MeetingDecisionRepositoryImpl(this.remoteDataSource);

  @override
  Future<MeetingDecision> submitMeetingDecision({
    required DateTime meetingDate,
    required DateTime meetingTime,
    required String decision,
    required int durationMinutes,
    required String token,
  }) async {
    return await remoteDataSource.submitMeetingDecision(
      meetingDate: meetingDate,
      meetingTime: meetingTime,
      decision: decision,
      durationMinutes: durationMinutes,
      token: token,
    );
  }
}
