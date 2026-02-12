class MeetingDecision {
  final String id;
  final DateTime meetingDate;
  final DateTime meetingTime;
  final String decision; // 'accept' or 'reject'
  final int durationMinutes;
  final String requestId;
  final DateTime createdAt;

  MeetingDecision({
    required this.id,
    required this.meetingDate,
    required this.meetingTime,
    required this.decision,
    required this.durationMinutes,
    required this.requestId,
    required this.createdAt,
  });

  // Combine date and time into a single DateTime
  DateTime get meetingDateTime => DateTime(
    meetingDate.year,
    meetingDate.month,
    meetingDate.day,
    meetingTime.hour,
    meetingTime.minute,
  );

  @override
  String toString() =>
      'MeetingDecision(id: $id, decision: $decision, duration: $durationMinutes min, date: ${meetingDate.toIso8601String()})';
}
