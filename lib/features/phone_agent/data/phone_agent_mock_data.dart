import '../models/phone_call_model.dart';

/// Mock calls for Phone Agent list.
List<PhoneCallModel> get mockPhoneCalls => [
  const PhoneCallModel(
    id: '1',
    callerName: 'Sarah Johnson',
    phoneNumber: '+1 (555) 234-5678',
    date: 'Feb 23, 2026',
    time: '10:45 AM',
    duration: '5:23',
    priority: 'high',
    status: 'pending',
    summary: 'Interested in custom mobile app development. Budget: \$50k-75k. Wants to schedule consultation.',
    category: 'appointment',
  ),
  const PhoneCallModel(
    id: '2',
    callerName: 'Michael Chen',
    phoneNumber: '+1 (555) 876-5432',
    date: 'Feb 23, 2026',
    time: '09:15 AM',
    duration: '3:45',
    priority: 'high',
    status: 'scheduled',
    summary: 'Asked about AI integration pricing. Meeting scheduled for Feb 25 at 2 PM.',
    category: 'pricing',
  ),
  const PhoneCallModel(
    id: '3',
    callerName: 'Emma Rodriguez',
    phoneNumber: '+1 (555) 345-6789',
    date: 'Feb 22, 2026',
    time: '04:30 PM',
    duration: '2:15',
    priority: 'medium',
    status: 'completed',
    summary: 'General inquiry about web development services. Sent follow-up email with portfolio.',
    category: 'general',
  ),
  const PhoneCallModel(
    id: '4',
    callerName: 'David Kim',
    phoneNumber: '+1 (555) 567-8901',
    date: 'Feb 22, 2026',
    time: '02:20 PM',
    duration: '7:12',
    priority: 'high',
    status: 'pending',
    summary: 'Technical questions about React Native vs Flutter. Needs expert consultation urgently.',
    category: 'technical',
  ),
  const PhoneCallModel(
    id: '5',
    callerName: 'Lisa Thompson',
    phoneNumber: '+1 (555) 789-0123',
    date: 'Feb 22, 2026',
    time: '11:00 AM',
    duration: '4:30',
    priority: 'medium',
    status: 'pending',
    summary: 'Asked about maintenance packages and ongoing support pricing for existing app.',
    category: 'pricing',
  ),
  const PhoneCallModel(
    id: '6',
    callerName: 'James Wilson',
    phoneNumber: '+1 (555) 432-1098',
    date: 'Feb 21, 2026',
    time: '03:45 PM',
    duration: '1:50',
    priority: 'low',
    status: 'dismissed',
    summary: 'General business hours inquiry. No follow-up needed.',
    category: 'general',
  ),
];

/// Get full detail for a call (mock). In real app, fetch by id.
PhoneCallDetailModel getCallDetail(PhoneCallModel call) {
  final conversation = call.id == '1'
      ? [
          const ConversationMessage(role: 'agent', text: "Hello! Thank you for calling AVA Development. I'm your AI assistant. How can I help you today?", timestamp: '10:45:03'),
          const ConversationMessage(role: 'caller', text: "Hi, I'm Sarah Johnson from TechStartup Inc. We're looking to develop a mobile application for our fintech business.", timestamp: '10:45:15'),
          const ConversationMessage(role: 'agent', text: "That's exciting! I'd be happy to help. Could you tell me more about your project requirements and what platforms you're targeting?", timestamp: '10:45:22'),
          const ConversationMessage(role: 'caller', text: 'We need both iOS and Android apps. It\'s a fintech app that will handle payments, so security is critical. We\'ve worked with agencies before but weren\'t satisfied.', timestamp: '10:45:45'),
          const ConversationMessage(role: 'agent', text: "I understand. Security is our top priority, especially for financial applications. What's your timeline and budget range for this project?", timestamp: '10:45:58'),
          const ConversationMessage(role: 'caller', text: "We're looking at 3-4 months development time. Our budget is between \$50,000 and \$75,000. Is that feasible?", timestamp: '10:46:20'),
          const ConversationMessage(role: 'agent', text: "Yes, that's definitely within a feasible range for a high-quality fintech mobile application. For a custom app with secure payment integration on both platforms, our typical pricing is \$55,000 - \$85,000 depending on specific features.", timestamp: '10:46:35'),
          const ConversationMessage(role: 'caller', text: "That sounds good. What would be the next steps? I'd like to schedule a consultation with your team.", timestamp: '10:47:08'),
          const ConversationMessage(role: 'agent', text: "Perfect! I'll flag this as a high-priority consultation request. Our team will reach out to you within 2 hours to schedule a detailed consultation. Can I confirm your best email for follow-up?", timestamp: '10:47:20'),
          const ConversationMessage(role: 'caller', text: 'Yes, it\'s sarah.johnson@techstartup.com', timestamp: '10:47:35'),
          const ConversationMessage(role: 'agent', text: "Great! I've noted everything. You'll receive a confirmation email shortly, and someone from our team will contact you today. Is there anything else I can help you with?", timestamp: '10:47:48'),
          const ConversationMessage(role: 'caller', text: "No, that's all. Thank you so much!", timestamp: '10:48:05'),
          const ConversationMessage(role: 'agent', text: "You're welcome, Sarah! We're excited to work with you. Have a great day!", timestamp: '10:48:12'),
        ]
      : <ConversationMessage>[];

  return PhoneCallDetailModel.fromCall(
    call,
    email: call.id == '1' ? 'sarah.johnson@techstartup.com' : null,
    company: call.id == '1' ? 'TechStartup Inc.' : null,
    tags: call.id == '1' ? ['Urgent', 'High Budget', 'Mobile Development'] : [],
    keyPoints: call.id == '1'
        ? [
            'Looking to build a fintech mobile app',
            'Budget range: \$50,000 - \$75,000',
            'Timeline: 3-4 months',
            'Needs both iOS and Android',
            'Requires secure payment integration',
            'Previous experience with app agencies was unsatisfactory',
          ]
        : [],
    conversation: conversation,
    aiAnalysis: const AiAnalysisModel(
      sentiment: 'Positive',
      intentConfidence: '95%',
      leadQuality: 'High',
      urgency: 'High',
      estimatedValue: '\$50k-75k',
      nextAction: 'Schedule consultation call within 24 hours',
    ),
  );
}
