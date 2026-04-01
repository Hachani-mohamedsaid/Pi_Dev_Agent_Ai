// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum ChallengeType {
  voice_email,
  social_sharing,
  profile_update,
  meeting_complete,
  invite_friend,
  premium_upgrade,
  daily_streak,
  ai_interaction,
  api_integration,
  achievement_unlock,
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String icon; // lucide icon name
  final int points;
  final Color color;
  final ChallengeType type;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? longDescription;
  final List<String> steps;
  final bool requiresVoice;
  final bool requiresPayment;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.color,
    required this.type,
    this.isCompleted = false,
    this.completedAt,
    this.longDescription,
    this.steps = const <String>[],
    this.requiresVoice = false,
    this.requiresPayment = false,
  });

  Challenge copyWith({bool? isCompleted, DateTime? completedAt}) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      icon: icon,
      points: points,
      color: color,
      type: type,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      longDescription: longDescription,
      steps: steps,
      requiresVoice: requiresVoice,
      requiresPayment: requiresPayment,
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final int totalPoints;
  final List<String> completedChallengeIds;
  final int rank; // based on points
  final bool isPremium;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.totalPoints,
    this.completedChallengeIds = const <String>[],
    required this.rank,
    this.isPremium = false,
  });

  UserProfile copyWith({
    int? totalPoints,
    List<String>? completedChallengeIds,
    int? rank,
    bool? isPremium,
  }) {
    return UserProfile(
      id: id,
      name: name,
      email: email,
      avatar: avatar,
      totalPoints: totalPoints ?? this.totalPoints,
      completedChallengeIds:
          completedChallengeIds ?? this.completedChallengeIds,
      rank: rank ?? this.rank,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

// Mock data for challenges
List<Challenge> getMockChallenges() {
  return [
    Challenge(
      id: 'ch_voice_email',
      title: 'Voice Email Master',
      description: 'Send an email using voice commands',
      icon: 'mic',
      points: 100,
      color: const Color(0xFF6366F1),
      type: ChallengeType.voice_email,
      requiresVoice: true,
      longDescription:
          'Use voice-to-text to compose and send an email directly from AVA assistant.',
      steps: const [
        'Open AVA Chat',
        'Say: "Send email to [name]"',
        'Compose message using voice',
        'Confirm and send',
      ],
    ),
    Challenge(
      id: 'ch_social_share',
      title: 'Social Butterfly',
      description: 'Share AVA with 3 friends on social media',
      icon: 'share2',
      points: 150,
      color: const Color(0xFF06B6D4),
      type: ChallengeType.social_sharing,
      longDescription:
          'Spread the word about AVA and get your friends to download it.',
      steps: const [
        'Tap Share from Profile',
        'Select social platform',
        'Share with at least 3 friends',
        'They must join within 7 days',
      ],
    ),
    Challenge(
      id: 'ch_profile_update',
      title: 'Complete Profile Pro',
      description: 'Update all profile information and add a profile picture',
      icon: 'user-check',
      points: 75,
      color: const Color(0xFF10B981),
      type: ChallengeType.profile_update,
      longDescription:
          'Complete your profile with all details including photo for a professional appearance.',
      steps: const [
        'Go to Profile Settings',
        'Add profile picture',
        'Fill all bio fields',
        'Add social links',
        'Save changes',
      ],
    ),
    Challenge(
      id: 'ch_meeting_complete',
      title: 'Meeting Master',
      description: 'Complete and export 5 meetings with briefings',
      icon: 'calendar',
      points: 200,
      color: const Color(0xFFF59E0B),
      type: ChallengeType.meeting_complete,
      longDescription:
          'Use the full meeting intelligence pipeline to prepare and analyze investor meetings.',
      steps: const [
        'Setup 5 investor meetings',
        'Generate full briefings',
        'Complete each meeting',
        'Export reports for 5 meetings',
      ],
    ),
    Challenge(
      id: 'ch_invite_friend',
      title: 'Community Builder',
      description: 'Invite a friend and they must complete a meeting',
      icon: 'users',
      points: 250,
      color: const Color(0xFFEC4899),
      type: ChallengeType.invite_friend,
      longDescription:
          'Grow the AVA community by inviting someone and having them use the platform.',
      steps: const [
        'Send invite link to friend',
        'They sign up and verify email',
        'They complete their first meeting',
        'Both of you earn bonus points',
      ],
    ),
    Challenge(
      id: 'ch_premium_upgrade',
      title: 'Premium Champion',
      description: 'Upgrade to premium plan and enjoy exclusive features',
      icon: 'crown',
      points: 500,
      color: const Color(0xFFD946EF),
      type: ChallengeType.premium_upgrade,
      requiresPayment: true,
      longDescription:
          'Unlock premium features including advanced AI analysis, priority support, and more.',
      steps: const [
        'Go to Subscription',
        'Choose premium plan',
        'Complete payment',
        'Enjoy exclusive features',
      ],
    ),
    Challenge(
      id: 'ch_daily_streak',
      title: 'Consistency King',
      description: 'Log in for 7 consecutive days',
      icon: 'zap',
      points: 120,
      color: const Color(0xFFFCD34D),
      type: ChallengeType.daily_streak,
      longDescription:
          'Build a habit by using AVA every single day for a full week.',
      steps: const [
        'Log in today',
        'Log in tomorrow',
        'Continue for 7 days straight',
        'No missed days',
      ],
    ),
    Challenge(
      id: 'ch_ai_interaction',
      title: 'AI Conversationalist',
      description: 'Have 10 conversations with AVA AI assistant',
      icon: 'message-circle',
      points: 100,
      color: const Color(0xFF14B8A6),
      type: ChallengeType.ai_interaction,
      longDescription:
          'Engage deeply with AVA\'s AI for insights and assistance on various topics.',
      steps: const [
        'Open Chat',
        'Ask AVA 10 questions',
        'Get meaningful responses',
        'Explore different topics',
      ],
    ),
    Challenge(
      id: 'ch_api_integration',
      title: 'Developer Badge',
      description: 'Integrate AVA API in your workflow',
      icon: 'code',
      points: 300,
      color: const Color(0xFF8B5CF6),
      type: ChallengeType.api_integration,
      longDescription:
          'Advanced challenge: Use AVA\'s API to create custom integrations.',
      steps: const [
        'Access API documentation',
        'Generate API key',
        'Create integration',
        'Test and deploy',
      ],
    ),
    Challenge(
      id: 'ch_achievement_unlock',
      title: 'Achievement Hunter',
      description: 'Earn 5 achievement badges',
      icon: 'award',
      points: 180,
      color: const Color(0xFFFF6B6B),
      type: ChallengeType.achievement_unlock,
      longDescription:
          'Discover and unlock various achievements throughout the app.',
      steps: const [
        'Explore different features',
        'Complete various tasks',
        'Unlock 5 achievements',
        'Master the platform',
      ],
    ),
    Challenge(
      id: 'ch_first_export',
      title: 'First Export',
      description: 'Export your first AI report to PDF',
      icon: 'file-text',
      points: 90,
      color: const Color(0xFF22C55E),
      type: ChallengeType.meeting_complete,
      longDescription:
          'Learn the reporting flow by exporting your first AI generated summary.',
      steps: const [
        'Open one completed meeting',
        'Generate AI summary',
        'Tap Export',
        'Save the PDF report',
      ],
    ),
    Challenge(
      id: 'ch_profile_security',
      title: 'Security Setup',
      description: 'Enable verification and secure your account',
      icon: 'shield',
      points: 130,
      color: const Color(0xFF0EA5E9),
      type: ChallengeType.profile_update,
      longDescription:
          'Secure your account by verifying email and updating your recovery settings.',
      steps: const [
        'Verify your email',
        'Set a strong password',
        'Update phone number',
        'Confirm account security',
      ],
    ),
    Challenge(
      id: 'ch_weekly_planner',
      title: 'Weekly Planner',
      description: 'Plan 3 meetings for the coming week',
      icon: 'calendar-check',
      points: 160,
      color: const Color(0xFF14B8A6),
      type: ChallengeType.daily_streak,
      longDescription:
          'Build consistency by preparing your weekly pipeline of meetings in advance.',
      steps: const [
        'Open Meeting Planner',
        'Create 3 meetings',
        'Attach investor context',
        'Save weekly plan',
      ],
    ),
    Challenge(
      id: 'ch_power_user',
      title: 'Power User',
      description: 'Complete 3 advanced AI actions in one day',
      icon: 'sparkles',
      points: 220,
      color: const Color(0xFFF97316),
      type: ChallengeType.ai_interaction,
      longDescription:
          'Unlock advanced usage by combining voice, analytics, and export in one workflow.',
      steps: const [
        'Use voice to create content',
        'Generate AI analysis',
        'Export final output',
        'Finish all in same day',
      ],
    ),
    Challenge(
      id: 'ch_first_booking',
      title: 'First Booking',
      description: 'Create your first mobility booking in the app',
      icon: 'calendar',
      points: 110,
      color: const Color(0xFF3B82F6),
      type: ChallengeType.meeting_complete,
      longDescription:
          'Complete your first booking flow from estimate to confirmation.',
      steps: const [
        'Open Mobility section',
        'Create a route estimate',
        'Select a provider',
        'Confirm booking',
      ],
    ),
    Challenge(
      id: 'ch_team_invite_3',
      title: 'Team Connector',
      description: 'Invite 3 teammates to collaborate',
      icon: 'users',
      points: 190,
      color: const Color(0xFF6366F1),
      type: ChallengeType.invite_friend,
      longDescription:
          'Grow collaboration by inviting teammates and sharing your workspace.',
      steps: const [
        'Open Team settings',
        'Send 3 invitations',
        'At least 1 teammate accepts',
        'Share one resource with team',
      ],
    ),
    Challenge(
      id: 'ch_3day_streak',
      title: '3-Day Streak',
      description: 'Use the app for 3 consecutive days',
      icon: 'zap',
      points: 80,
      color: const Color(0xFFF59E0B),
      type: ChallengeType.daily_streak,
      longDescription:
          'Build consistency with a short three-day activation streak.',
      steps: const [
        'Open app on day 1',
        'Open app on day 2',
        'Open app on day 3',
      ],
    ),
    Challenge(
      id: 'ch_ai_briefing_5',
      title: 'Insight Analyst',
      description: 'Generate 5 AI briefings with actionable insights',
      icon: 'message-circle',
      points: 210,
      color: const Color(0xFF06B6D4),
      type: ChallengeType.ai_interaction,
      longDescription:
          'Master the AI assistant by creating five high quality briefings.',
      steps: const [
        'Select 5 different contexts',
        'Generate AI briefings',
        'Review insights',
        'Save each result',
      ],
    ),
    Challenge(
      id: 'ch_api_webhook',
      title: 'Webhook Builder',
      description: 'Connect one webhook to your workflow',
      icon: 'code',
      points: 240,
      color: const Color(0xFF8B5CF6),
      type: ChallengeType.api_integration,
      longDescription:
          'Complete one real integration using webhook events and payloads.',
      steps: const [
        'Create webhook endpoint',
        'Configure event source',
        'Validate payload',
        'Run successful test',
      ],
    ),
    Challenge(
      id: 'ch_master_10_badges',
      title: 'Badge Collector',
      description: 'Unlock 10 badges across all modules',
      icon: 'award',
      points: 320,
      color: const Color(0xFFEF4444),
      type: ChallengeType.achievement_unlock,
      longDescription:
          'Cross-module challenge to validate advanced usage of the platform.',
      steps: const [
        'Complete missions in 4 modules',
        'Reach 10 badges total',
        'Claim rewards in profile',
      ],
    ),
  ];
}

// Mock leaderboard data
List<UserProfile> getMockLeaderboard() {
  return [
    const UserProfile(
      id: 'user_1',
      name: 'Ahmed Hassan',
      email: 'ahmed.hassan@email.com',
      totalPoints: 2450,
      completedChallengeIds: [
        'ch_voice_email',
        'ch_social_share',
        'ch_profile_update',
        'ch_meeting_complete',
        'ch_premium_upgrade',
      ],
      rank: 1,
      isPremium: true,
    ),
    const UserProfile(
      id: 'user_2',
      name: 'Fatima Al Mansouri',
      email: 'fatima.mansouri@email.com',
      totalPoints: 2100,
      completedChallengeIds: [
        'ch_voice_email',
        'ch_social_share',
        'ch_profile_update',
        'ch_meeting_complete',
      ],
      rank: 2,
      isPremium: true,
    ),
    const UserProfile(
      id: 'user_3',
      name: 'Mohammed Youssef',
      email: 'mohammed.y@email.com',
      totalPoints: 1850,
      completedChallengeIds: [
        'ch_voice_email',
        'ch_profile_update',
        'ch_daily_streak',
      ],
      rank: 3,
      isPremium: false,
    ),
    const UserProfile(
      id: 'user_4',
      name: 'Layla Ahmed',
      email: 'layla.ahmed@email.com',
      totalPoints: 1620,
      completedChallengeIds: [
        'ch_social_share',
        'ch_meeting_complete',
        'ch_ai_interaction',
      ],
      rank: 4,
      isPremium: false,
    ),
    const UserProfile(
      id: 'user_5',
      name: 'Karim Ibrahim',
      email: 'karim.ibrahim@email.com',
      totalPoints: 1420,
      completedChallengeIds: [
        'ch_profile_update',
        'ch_daily_streak',
        'ch_ai_interaction',
      ],
      rank: 5,
      isPremium: false,
    ),
    const UserProfile(
      id: 'user_6',
      name: 'Noor Al Mazrouei',
      email: 'noor.mazrouei@email.com',
      totalPoints: 1280,
      completedChallengeIds: ['ch_voice_email', 'ch_social_share'],
      rank: 6,
      isPremium: false,
    ),
    const UserProfile(
      id: 'user_7',
      name: 'Zainab Al Nomani',
      email: 'zainab.nomani@email.com',
      totalPoints: 1050,
      completedChallengeIds: ['ch_profile_update', 'ch_ai_interaction'],
      rank: 7,
      isPremium: false,
    ),
    const UserProfile(
      id: 'user_8',
      name: 'Omar Khalil',
      email: 'omar.khalil@email.com',
      totalPoints: 890,
      completedChallengeIds: ['ch_daily_streak'],
      rank: 8,
      isPremium: false,
    ),
  ];
}
