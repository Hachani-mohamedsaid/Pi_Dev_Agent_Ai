/// A recent meeting item for the Meeting Hub list.
class RecentMeetingModel {
  final String id;
  final String title;
  final String date;
  final String duration;
  final int participants;

  const RecentMeetingModel({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.participants,
  });
}

/// One line in a meeting transcript.
class TranscriptLineModel {
  final String speaker;
  final String text;
  final String timestamp;

  const TranscriptLineModel({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });
}

/// Full meeting transcript with AI summary (key points, action items, decisions).
class MeetingTranscriptModel {
  final String id;
  final String title;
  final String date;
  final String duration;
  final List<String> participants;
  final List<String> keyPoints;
  final List<String> actionItems;
  final List<String> decisions;
  final List<TranscriptLineModel> fullTranscript;

  const MeetingTranscriptModel({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.participants,
    required this.keyPoints,
    required this.actionItems,
    required this.decisions,
    required this.fullTranscript,
  });
}

/// Meeting detail returned by the backend (includes transcript + summary).
class MeetingDetailModel {
  final String id;
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final List<String> participants;
  final List<TranscriptLineModel> transcript;
  final List<String> keyPoints;
  final List<String> actionItems;
  final List<String> decisions;
  final String summary;
  final DateTime? createdAt;

  const MeetingDetailModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.participants,
    required this.transcript,
    required this.keyPoints,
    required this.actionItems,
    required this.decisions,
    required this.summary,
    required this.createdAt,
  });
}
