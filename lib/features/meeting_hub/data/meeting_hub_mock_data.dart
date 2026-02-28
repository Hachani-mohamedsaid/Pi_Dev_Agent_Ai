import '../models/meeting_model.dart';

/// Mock recent meetings for Meeting Hub screen.
List<RecentMeetingModel> get mockRecentMeetings => [
  const RecentMeetingModel(
    id: '1',
    title: 'Q1 Investor Review',
    date: 'Feb 26, 2026',
    duration: '45 min',
    participants: 4,
  ),
  const RecentMeetingModel(
    id: '2',
    title: 'Product Strategy Session',
    date: 'Feb 25, 2026',
    duration: '32 min',
    participants: 3,
  ),
  const RecentMeetingModel(
    id: '3',
    title: 'Team Standup',
    date: 'Feb 24, 2026',
    duration: '18 min',
    participants: 7,
  ),
];

/// Default transcript for transcript screen (static for now).
MeetingTranscriptModel get defaultMeetingTranscript => const MeetingTranscriptModel(
  id: '1',
  title: 'Product Strategy Session',
  date: 'Feb 26, 2026',
  duration: '45 min',
  participants: ['You', 'Sarah Chen', 'Mike Rodriguez', 'Alex Kim'],
  keyPoints: [
    'Focus on mobile-first user experience',
    'Q4 analytics show 60% mobile traffic growth',
    'Budget allocation for mobile development',
    'Follow-up meeting scheduled for next week',
  ],
  actionItems: [
    'Review Q4 analytics document',
    'Prepare mobile development proposal',
    'Schedule budget discussion with finance team',
  ],
  decisions: [
    'Prioritize mobile platform development',
    'Allocate additional resources to UX team',
  ],
  fullTranscript: [
    TranscriptLineModel(speaker: 'Sarah Chen', text: "Thanks everyone for joining. Let's dive into our product strategy for Q1.", timestamp: '0:00'),
    TranscriptLineModel(speaker: 'Mike Rodriguez', text: "I've prepared the latest analytics. The numbers are quite interesting.", timestamp: '0:15'),
    TranscriptLineModel(speaker: 'You', text: "Great, I'm particularly interested in the mobile metrics.", timestamp: '0:30'),
    TranscriptLineModel(speaker: 'Sarah Chen', text: "I think we should focus on the user experience first.", timestamp: '1:00'),
    TranscriptLineModel(speaker: 'Mike Rodriguez', text: 'Agreed. The analytics show that mobile traffic is increasing by 60% quarter over quarter.', timestamp: '1:15'),
    TranscriptLineModel(speaker: 'You', text: "Let me pull up those numbers for everyone.", timestamp: '1:45'),
    TranscriptLineModel(speaker: 'Sarah Chen', text: "That would be helpful, thanks!", timestamp: '2:00'),
    TranscriptLineModel(speaker: 'Alex Kim', text: "Based on these trends, we should definitely prioritize mobile development.", timestamp: '2:30'),
    TranscriptLineModel(speaker: 'You', text: "Agreed. Let's schedule a follow-up to discuss budget allocation.", timestamp: '3:00'),
    TranscriptLineModel(speaker: 'Sarah Chen', text: "Perfect. I'll send out a calendar invite for next week.", timestamp: '3:15'),
    TranscriptLineModel(speaker: 'Mike Rodriguez', text: "Sounds good. I'll prepare the cost analysis before then.", timestamp: '3:30'),
    TranscriptLineModel(speaker: 'Alex Kim', text: "I can contribute the technical feasibility assessment.", timestamp: '3:45'),
    TranscriptLineModel(speaker: 'You', text: "Excellent. Let's make sure we have all stakeholders aligned.", timestamp: '4:00'),
    TranscriptLineModel(speaker: 'Sarah Chen', text: "Agreed. This is going to be a significant initiative.", timestamp: '4:15'),
  ],
);

/// AI suggestion during active meeting.
class AiSuggestionItem {
  final String text;
  final String context;

  const AiSuggestionItem({required this.text, required this.context});
}

List<AiSuggestionItem> get mockAiSuggestions => const [
  AiSuggestionItem(text: "That's a great point. Could you elaborate on the implementation timeline?", context: 'Follow-up question'),
  AiSuggestionItem(text: "I agree with your assessment. Let's schedule a follow-up to discuss the budget allocation.", context: 'Agreement + Action'),
  AiSuggestionItem(text: "Based on our previous discussion, we should prioritize the mobile platform first.", context: 'Strategic suggestion'),
  AiSuggestionItem(text: "Can we share the Q4 metrics document in the chat for everyone's reference?", context: 'Resource request'),
];

/// Live transcript line during active meeting.
class LiveTranscriptLine {
  final String speaker;
  final String text;
  final String time;

  const LiveTranscriptLine({required this.speaker, required this.text, required this.time});
}

List<LiveTranscriptLine> get mockLiveTranscript => const [
  LiveTranscriptLine(speaker: 'Sarah', text: "I think we should focus on the user experience first.", time: '2:34 PM'),
  LiveTranscriptLine(speaker: 'Mike', text: 'Agreed. The analytics show that mobile traffic is increasing.', time: '2:34 PM'),
  LiveTranscriptLine(speaker: 'You', text: 'Let me pull up those numbers for everyone.', time: '2:35 PM'),
  LiveTranscriptLine(speaker: 'Sarah', text: "That would be helpful, thanks!", time: '2:35 PM'),
];
