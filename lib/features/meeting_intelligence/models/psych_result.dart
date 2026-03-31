import '../meeting_json_util.dart';

/// Response from POST /meetings/:id/briefing/psych
class PsychResult {
  const PsychResult({
    required this.personalityType,
    required this.dominantTraits,
    required this.communicationPreference,
    required this.decisionStyle,
    required this.likelyObjections,
    required this.questionsToAsk,
    required this.howToApproach,
    required this.confidenceLevel,
  });

  final String personalityType;
  final List<String> dominantTraits;
  final String communicationPreference;
  final String decisionStyle;
  final List<String> likelyObjections;
  final List<String> questionsToAsk;
  final String howToApproach;

  /// `high` | `medium` | `low` — only `low` shows the disclaimer banner.
  final String confidenceLevel;

  factory PsychResult.fromJson(Map<String, dynamic> j) => PsychResult(
        personalityType: pickString(
          j,
          const ['personality_type', 'personalityType'],
        ),
        dominantTraits: pickStringList(
          j,
          const ['dominant_traits', 'dominantTraits'],
        ),
        communicationPreference: pickString(
          j,
          const ['communication_preference', 'communicationPreference'],
        ),
        decisionStyle: pickString(j, const ['decision_style', 'decisionStyle']),
        likelyObjections: pickStringList(
          j,
          const ['likely_objections', 'likelyObjections'],
        ),
        questionsToAsk: pickStringList(
          j,
          const ['questions_to_ask', 'questionsToAsk'],
        ),
        howToApproach: pickString(j, const ['how_to_approach', 'howToApproach']),
        confidenceLevel: pickString(
          j,
          const ['confidence_level', 'confidenceLevel'],
          'medium',
        ),
      );

  static PsychResult mock() => const PsychResult(
        personalityType: 'Analytical Pragmatist',
        dominantTraits: [
          'Analytical',
          'Risk-Conscious',
          'Data-First',
          'Detail-Oriented',
        ],
        communicationPreference:
            'Marco prefers structured, evidence-based conversations. '
            'Lead with numbers, follow with story — never the reverse. '
            'He responds well to data before narrative.',
        decisionStyle:
            'He is a deliberate decision-maker who rarely commits in a '
            'first meeting. Expect him to ask for follow-up materials. '
            'This is not rejection — it is his process. Do not push for '
            'commitment in the room.',
        likelyObjections: [
          'Your valuation seems high for a pre-revenue stage',
          'Show me comparable exits in European FinTech',
          'What is your 18-month burn rate and runway?',
        ],
        questionsToAsk: [
          'How do you see traction milestones aligning with your current portfolio strategy?',
          'What has been the most successful go-to-market approach in your FinTech investments?',
        ],
        howToApproach:
            'Lead with a structured, number-backed narrative. Marco will '
            'challenge every vague claim — have evidence ready for each '
            'assertion. Once he sees you know your numbers, his tone will '
            'shift — that is your signal to bring in the broader story. '
            'Avoid ultimatums or pressure tactics entirely.',
        confidenceLevel: 'high',
      );
}
