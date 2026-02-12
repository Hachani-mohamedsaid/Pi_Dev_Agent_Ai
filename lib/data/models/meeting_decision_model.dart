import '../../domain/entities/meeting_decision.dart';

class MeetingDecisionModel extends MeetingDecision {
  MeetingDecisionModel({
    required super.id,
    required super.meetingDate,
    required super.meetingTime,
    required super.decision,
    required super.durationMinutes,
    required super.requestId,
    required super.createdAt,
  });

  factory MeetingDecisionModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    final meetingDateString = json['meetingDate'] as String?;
    final meetingTimeString = json['meetingTime'] as String?;
    final createdAtString = json['createdAt'] as String?;

    return MeetingDecisionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      meetingDate: meetingDateString != null
          ? DateTime.parse(meetingDateString)
          : now,
      meetingTime: meetingTimeString != null
          ? DateTime.parse(meetingTimeString)
          : now,
      decision: json['decision'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      requestId: json['requestId'] as String? ?? '',
      createdAt: createdAtString != null
          ? DateTime.parse(createdAtString)
          : now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'meetingDate': meetingDate.toIso8601String(),
    'meetingTime': meetingTime.toIso8601String(),
    'decision': decision,
    'durationMinutes': durationMinutes,
    'requestId': requestId,
    'createdAt': createdAt.toIso8601String(),
  };
}
