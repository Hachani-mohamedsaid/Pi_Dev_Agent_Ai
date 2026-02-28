/// Model for a call in the Phone Agent list.
class PhoneCallModel {
  final String id;
  final String callerName;
  final String phoneNumber;
  final String date;
  final String time;
  final String duration;
  final String priority; // high, medium, low
  final String status; // pending, scheduled, completed, dismissed
  final String summary;
  final String category; // pricing, appointment, general, technical

  const PhoneCallModel({
    required this.id,
    required this.callerName,
    required this.phoneNumber,
    required this.date,
    required this.time,
    required this.duration,
    required this.priority,
    required this.status,
    required this.summary,
    required this.category,
  });
}

/// Extended model for call detail screen.
class PhoneCallDetailModel extends PhoneCallModel {
  final String? email;
  final String? company;
  final List<String> tags;
  final List<String> keyPoints;
  final List<ConversationMessage> conversation;
  final AiAnalysisModel? aiAnalysis;

  const PhoneCallDetailModel({
    required super.id,
    required super.callerName,
    required super.phoneNumber,
    required super.date,
    required super.time,
    required super.duration,
    required super.priority,
    required super.status,
    required super.summary,
    required super.category,
    this.email,
    this.company,
    this.tags = const [],
    this.keyPoints = const [],
    this.conversation = const [],
    this.aiAnalysis,
  });

  factory PhoneCallDetailModel.fromCall(PhoneCallModel call, {
    String? email,
    String? company,
    List<String>? tags,
    List<String>? keyPoints,
    List<ConversationMessage>? conversation,
    AiAnalysisModel? aiAnalysis,
  }) {
    return PhoneCallDetailModel(
      id: call.id,
      callerName: call.callerName,
      phoneNumber: call.phoneNumber,
      date: call.date,
      time: call.time,
      duration: call.duration,
      priority: call.priority,
      status: call.status,
      summary: call.summary,
      category: call.category,
      email: email,
      company: company,
      tags: tags ?? [],
      keyPoints: keyPoints ?? [],
      conversation: conversation ?? [],
      aiAnalysis: aiAnalysis,
    );
  }
}

class ConversationMessage {
  final String role; // agent, caller
  final String text;
  final String timestamp;

  const ConversationMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class AiAnalysisModel {
  final String sentiment;
  final String intentConfidence;
  final String leadQuality;
  final String urgency;
  final String estimatedValue;
  final String nextAction;

  const AiAnalysisModel({
    required this.sentiment,
    required this.intentConfidence,
    required this.leadQuality,
    required this.urgency,
    required this.estimatedValue,
    required this.nextAction,
  });
}
