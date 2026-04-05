import 'package:flutter/foundation.dart';

@immutable
class WellbeingSection {
  const WellbeingSection({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

@immutable
class WellbeingQuestion {
  const WellbeingQuestion({
    required this.index,
    required this.sectionId,
    required this.text,
    this.reverseScore = false,
  });

  final int index;
  final String sectionId;
  final String text;

  /// When true, raw answer `a` is mapped to stress as `6 - a` (higher = less stress in the item).
  final bool reverseScore;
}

const WellbeingSection kWellbeingSectionA = WellbeingSection(
  id: 'A',
  title: 'DECISION & COGNITIVE LOAD',
  subtitle: 'Mental processing & clarity',
);

const WellbeingSection kWellbeingSectionB = WellbeingSection(
  id: 'B',
  title: 'EMOTIONAL & SOCIAL PRESSURE',
  subtitle: 'Anxiety, guilt & isolation',
);

const WellbeingSection kWellbeingSectionC = WellbeingSection(
  id: 'C',
  title: 'PHYSICAL & ENERGY DEPLETION',
  subtitle: 'Body signals & vitality',
);

const List<WellbeingSection> kWellbeingSections = [
  kWellbeingSectionA,
  kWellbeingSectionB,
  kWellbeingSectionC,
];

/// Fixed order Q1…Q9 (matches entrepreneur diagnostic copy).
const List<WellbeingQuestion> kWellbeingQuestions = [
  WellbeingQuestion(
    index: 1,
    sectionId: 'A',
    text:
        'I feel mentally paralyzed by the number of decisions I must make daily.',
  ),
  WellbeingQuestion(
    index: 2,
    sectionId: 'A',
    text: 'I feel mentally clear and in control of my workload.',
    reverseScore: true,
  ),
  WellbeingQuestion(
    index: 3,
    sectionId: 'A',
    text: 'I go to bed still mentally processing work problems.',
  ),
  WellbeingQuestion(
    index: 4,
    sectionId: 'B',
    text: 'I feel alone in carrying the weight of my responsibilities.',
  ),
  WellbeingQuestion(
    index: 5,
    sectionId: 'B',
    text: "I feel guilty when I'm not working, even during rest time.",
  ),
  WellbeingQuestion(
    index: 6,
    sectionId: 'B',
    text: 'I feel anxious about my finances or business performance.',
  ),
  WellbeingQuestion(
    index: 7,
    sectionId: 'C',
    text: 'I feel physically exhausted despite getting enough sleep.',
  ),
  WellbeingQuestion(
    index: 8,
    sectionId: 'C',
    text:
        'I notice physical symptoms: tension, headaches, or fatigue.',
  ),
  WellbeingQuestion(
    index: 9,
    sectionId: 'C',
    text:
        'I rely on caffeine or stimulants to maintain my performance.',
  ),
];
