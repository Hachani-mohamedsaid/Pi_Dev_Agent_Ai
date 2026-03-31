import '../meeting_json_util.dart';

/// Response from POST /meetings/:id/briefing/culture
class CulturalResult {
  const CulturalResult({
    required this.dos,
    required this.donts,
    required this.communicationStyle,
    required this.negotiationApproach,
    required this.openingLine,
    required this.meetingFlow,
  });

  final List<String> dos;
  final List<String> donts;
  final String communicationStyle;
  final String negotiationApproach;
  final String openingLine;
  final List<String> meetingFlow;

  factory CulturalResult.fromJson(Map<String, dynamic> j) => CulturalResult(
        dos: pickStringList(j, const ['dos']),
        donts: pickStringList(j, const ['donts']),
        communicationStyle: pickString(
          j,
          const ['communication_style', 'communicationStyle'],
        ),
        negotiationApproach: pickString(
          j,
          const ['negotiation_approach', 'negotiationApproach'],
        ),
        openingLine: pickString(j, const ['opening_line', 'openingLine']),
        meetingFlow: pickStringList(j, const ['meeting_flow', 'meetingFlow']),
      );

  /// Local preview when backend is unavailable (dev only).
  static CulturalResult mock() => const CulturalResult(
        dos: [
          'Open with brief rapport before diving into the deck',
          'Show genuine passion and a clear view of the next milestones',
          'Dress one notch above the meeting format — polish reads as respect',
        ],
        donts: [
          'Rush straight into valuation without aligning on agenda',
          'Use aggressive tactics or ultimatums early in the conversation',
          'Appear cold, overly scripted, or emotionally detached',
        ],
        communicationStyle:
            'Many investors warm up with light context before numbers. '
            'Build clarity and trust first — business follows. '
            'Stay composed; let enthusiasm show without crowding the room.',
        negotiationApproach:
            'Expect pushback on assumptions; answer with evidence. '
            'Decisions may take follow-ups — end with crisp next steps '
            'rather than forcing a same-day yes.',
        openingLine:
            '"Thanks for making time — I\'d love to align on what success '
            'looks like for you in the first ninety days, then walk you '
            'through how we get there."',
        meetingFlow: [
          'Personal warm-up',
          'Sector context',
          'Pitch deck',
          'Close & next steps',
        ],
      );
}
