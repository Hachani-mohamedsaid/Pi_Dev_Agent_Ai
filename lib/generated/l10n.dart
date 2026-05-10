// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Ready to transform your day?`
  String get readyToTransform {
    return Intl.message(
      'Ready to transform your day?',
      name: 'readyToTransform',
      desc: '',
      args: [],
    );
  }

  /// `Join thousands already using AVA to boost productivity.`
  String get joinThousands {
    return Intl.message(
      'Join thousands already using AVA to boost productivity.',
      name: 'joinThousands',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get alreadyHaveAccount {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `AVA`
  String get ava {
    return Intl.message('AVA', name: 'ava', desc: '', args: []);
  }

  /// `Your personal AI assistant`
  String get yourPersonalAIAssistant {
    return Intl.message(
      'Your personal AI assistant',
      name: 'yourPersonalAIAssistant',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Voice Assistant`
  String get voiceAssistant {
    return Intl.message(
      'Voice Assistant',
      name: 'voiceAssistant',
      desc: '',
      args: [],
    );
  }

  /// `Talk naturally with AI. Get instant answers and control your tasks by voice.`
  String get voiceAssistantDesc {
    return Intl.message(
      'Talk naturally with AI. Get instant answers and control your tasks by voice.',
      name: 'voiceAssistantDesc',
      desc: '',
      args: [],
    );
  }

  /// `Smart Insights`
  String get smartInsights {
    return Intl.message(
      'Smart Insights',
      name: 'smartInsights',
      desc: '',
      args: [],
    );
  }

  /// `AI analyzes your patterns and suggests actions to boost your productivity.`
  String get smartInsightsDesc {
    return Intl.message(
      'AI analyzes your patterns and suggests actions to boost your productivity.',
      name: 'smartInsightsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Privacy First`
  String get privacyFirst {
    return Intl.message(
      'Privacy First',
      name: 'privacyFirst',
      desc: '',
      args: [],
    );
  }

  /// `Your data stays on your device. Enterprise-grade security for your peace of mind.`
  String get privacyFirstDesc {
    return Intl.message(
      'Your data stays on your device. Enterprise-grade security for your peace of mind.',
      name: 'privacyFirstDesc',
      desc: '',
      args: [],
    );
  }

  /// `Powerful Features`
  String get powerfulFeatures {
    return Intl.message(
      'Powerful Features',
      name: 'powerfulFeatures',
      desc: '',
      args: [],
    );
  }

  /// `Everything in one place`
  String get everythingInOnePlace {
    return Intl.message(
      'Everything in one place',
      name: 'everythingInOnePlace',
      desc: '',
      args: [],
    );
  }

  /// `AI features`
  String get aiFeatures {
    return Intl.message('AI features', name: 'aiFeatures', desc: '', args: []);
  }

  /// `Learning & insights`
  String get learningInsights {
    return Intl.message(
      'Learning & insights',
      name: 'learningInsights',
      desc: '',
      args: [],
    );
  }

  /// `Personalized tips and summaries based on your activity.`
  String get learningInsightsDesc {
    return Intl.message(
      'Personalized tips and summaries based on your activity.',
      name: 'learningInsightsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Connected services`
  String get connectedServices {
    return Intl.message(
      'Connected services',
      name: 'connectedServices',
      desc: '',
      args: [],
    );
  }

  /// `Manage integrations like Gmail, calendar, and more.`
  String get connectedServicesDesc {
    return Intl.message(
      'Manage integrations like Gmail, calendar, and more.',
      name: 'connectedServicesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Decision support`
  String get decisionSupport {
    return Intl.message(
      'Decision support',
      name: 'decisionSupport',
      desc: '',
      args: [],
    );
  }

  /// `Structured help for choices and trade-offs.`
  String get decisionSupportDesc {
    return Intl.message(
      'Structured help for choices and trade-offs.',
      name: 'decisionSupportDesc',
      desc: '',
      args: [],
    );
  }

  /// `Goals & growth`
  String get goalsGrowth {
    return Intl.message(
      'Goals & growth',
      name: 'goalsGrowth',
      desc: '',
      args: [],
    );
  }

  /// `Track objectives and build streaks.`
  String get goalsGrowthDesc {
    return Intl.message(
      'Track objectives and build streaks.',
      name: 'goalsGrowthDesc',
      desc: '',
      args: [],
    );
  }

  /// `Automation Rules`
  String get automationRules {
    return Intl.message(
      'Automation Rules',
      name: 'automationRules',
      desc: '',
      args: [],
    );
  }

  /// `Manage your AI automation rules`
  String get automationRulesDesc {
    return Intl.message(
      'Manage your AI automation rules',
      name: 'automationRulesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Challenges`
  String get challenges {
    return Intl.message('Challenges', name: 'challenges', desc: '', args: []);
  }

  /// `Complete challenges, earn points & climb the leaderboard`
  String get challengesDesc {
    return Intl.message(
      'Complete challenges, earn points & climb the leaderboard',
      name: 'challengesDesc',
      desc: '',
      args: [],
    );
  }

  /// `AI enthusiast`
  String get aiEnthusiast {
    return Intl.message(
      'AI enthusiast',
      name: 'aiEnthusiast',
      desc: '',
      args: [],
    );
  }

  /// `Tap to change photo`
  String get tapToChangePhoto {
    return Intl.message(
      'Tap to change photo',
      name: 'tapToChangePhoto',
      desc: '',
      args: [],
    );
  }

  /// `ImgBB key not configured: add it in lib/core/config/imgbb_config.dart`
  String get imgbbKeyMissing {
    return Intl.message(
      'ImgBB key not configured: add it in lib/core/config/imgbb_config.dart',
      name: 'imgbbKeyMissing',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get fullName {
    return Intl.message('Full Name', name: 'fullName', desc: '', args: []);
  }

  /// `Enter your name`
  String get enterYourName {
    return Intl.message(
      'Enter your name',
      name: 'enterYourName',
      desc: '',
      args: [],
    );
  }

  /// `Email Address`
  String get emailAddress {
    return Intl.message(
      'Email Address',
      name: 'emailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get enterYourEmail {
    return Intl.message(
      'Enter your email',
      name: 'enterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter your phone`
  String get enterYourPhone {
    return Intl.message(
      'Enter your phone',
      name: 'enterYourPhone',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get location {
    return Intl.message('Location', name: 'location', desc: '', args: []);
  }

  /// `Type to search cities…`
  String get typeToSearchCities {
    return Intl.message(
      'Type to search cities…',
      name: 'typeToSearchCities',
      desc: '',
      args: [],
    );
  }

  /// `Searching cities…`
  String get searchingCities {
    return Intl.message(
      'Searching cities…',
      name: 'searchingCities',
      desc: '',
      args: [],
    );
  }

  /// `No cities found for "{city}"`
  String noCitiesFound(Object city) {
    return Intl.message(
      'No cities found for "$city"',
      name: 'noCitiesFound',
      desc: '',
      args: [city],
    );
  }

  /// `Loading weather…`
  String get weatherLoading {
    return Intl.message(
      'Loading weather…',
      name: 'weatherLoading',
      desc: '',
      args: [],
    );
  }

  /// `Weather: {summary}`
  String weatherSummary(Object summary) {
    return Intl.message(
      'Weather: $summary',
      name: 'weatherSummary',
      desc: '',
      args: [summary],
    );
  }

  /// `Bio / Role`
  String get bioRole {
    return Intl.message('Bio / Role', name: 'bioRole', desc: '', args: []);
  }

  /// `Ex. AI Enthusiast`
  String get bioRoleHint {
    return Intl.message(
      'Ex. AI Enthusiast',
      name: 'bioRoleHint',
      desc: '',
      args: [],
    );
  }

  /// `Save Changes`
  String get saveChanges {
    return Intl.message(
      'Save Changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save photo`
  String get failedToSavePhoto {
    return Intl.message(
      'Failed to save photo',
      name: 'failedToSavePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Error while updating profile`
  String get profileUpdateError {
    return Intl.message(
      'Error while updating profile',
      name: 'profileUpdateError',
      desc: '',
      args: [],
    );
  }

  /// `Upload failed`
  String get uploadFailed {
    return Intl.message(
      'Upload failed',
      name: 'uploadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Photo updated successfully`
  String get photoUpdated {
    return Intl.message(
      'Photo updated successfully',
      name: 'photoUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Profile updated successfully`
  String get profileUpdated {
    return Intl.message(
      'Profile updated successfully',
      name: 'profileUpdated',
      desc: '',
      args: [],
    );
  }

  /// `AI-filtered and prioritized`
  String get aiFilteredAndPrioritized {
    return Intl.message(
      'AI-filtered and prioritized',
      name: 'aiFilteredAndPrioritized',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get all {
    return Intl.message('All', name: 'all', desc: '', args: []);
  }

  /// `Work`
  String get work {
    return Intl.message('Work', name: 'work', desc: '', args: []);
  }

  /// `Personal`
  String get personal {
    return Intl.message('Personal', name: 'personal', desc: '', args: []);
  }

  /// `Travel`
  String get travel {
    return Intl.message('Travel', name: 'travel', desc: '', args: []);
  }

  /// `General`
  String get general {
    return Intl.message('General', name: 'general', desc: '', args: []);
  }

  /// `Critical`
  String get critical {
    return Intl.message('Critical', name: 'critical', desc: '', args: []);
  }

  /// `Important`
  String get important {
    return Intl.message('Important', name: 'important', desc: '', args: []);
  }

  /// `Can wait`
  String get canWait {
    return Intl.message('Can wait', name: 'canWait', desc: '', args: []);
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Meeting Hub`
  String get meetingHub {
    return Intl.message('Meeting Hub', name: 'meetingHub', desc: '', args: []);
  }

  /// `Start or join a meeting with AI assistance`
  String get meetingHubSubtitle {
    return Intl.message(
      'Start or join a meeting with AI assistance',
      name: 'meetingHubSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Start Meeting`
  String get startMeeting {
    return Intl.message(
      'Start Meeting',
      name: 'startMeeting',
      desc: '',
      args: [],
    );
  }

  /// `Join Meeting`
  String get joinMeeting {
    return Intl.message(
      'Join Meeting',
      name: 'joinMeeting',
      desc: '',
      args: [],
    );
  }

  /// `Back to Home`
  String get backToHome {
    return Intl.message('Back to Home', name: 'backToHome', desc: '', args: []);
  }

  /// `Social Media Campaign`
  String get socialMediaCampaign {
    return Intl.message(
      'Social Media Campaign',
      name: 'socialMediaCampaign',
      desc: '',
      args: [],
    );
  }

  /// `Launch your product across all platforms`
  String get socialMediaCampaignSubtitle {
    return Intl.message(
      'Launch your product across all platforms',
      name: 'socialMediaCampaignSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Ongoing Projects`
  String get ongoingProjects {
    return Intl.message(
      'Ongoing Projects',
      name: 'ongoingProjects',
      desc: '',
      args: [],
    );
  }

  /// `view all`
  String get viewAll {
    return Intl.message('view all', name: 'viewAll', desc: '', args: []);
  }

  /// `AI Financial Simulation`
  String get aiFinancialSimulation {
    return Intl.message(
      'AI Financial Simulation',
      name: 'aiFinancialSimulation',
      desc: '',
      args: [],
    );
  }

  /// `Phone Agent`
  String get phoneAgent {
    return Intl.message('Phone Agent', name: 'phoneAgent', desc: '', args: []);
  }

  /// `Post on LinkedIn`
  String get postOnLinkedIn {
    return Intl.message(
      'Post on LinkedIn',
      name: 'postOnLinkedIn',
      desc: '',
      args: [],
    );
  }

  /// `Review Agenda`
  String get reviewAgenda {
    return Intl.message(
      'Review Agenda',
      name: 'reviewAgenda',
      desc: '',
      args: [],
    );
  }

  /// `Could not send feedback. Try again.`
  String get feedbackSendError {
    return Intl.message(
      'Could not send feedback. Try again.',
      name: 'feedbackSendError',
      desc: '',
      args: [],
    );
  }

  /// `Great! I will learn from this 👍`
  String get feedbackAccepted {
    return Intl.message(
      'Great! I will learn from this 👍',
      name: 'feedbackAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Got it. I'll improve next time 👌`
  String get feedbackDismissed {
    return Intl.message(
      'Got it. I\'ll improve next time 👌',
      name: 'feedbackDismissed',
      desc: '',
      args: [],
    );
  }

  /// `Proposal accepted. The project is saved on the server — it will appear in Sprints as soon as the API returns it (refresh or open the tab).`
  String get proposalAccepted {
    return Intl.message(
      'Proposal accepted. The project is saved on the server — it will appear in Sprints as soon as the API returns it (refresh or open the tab).',
      name: 'proposalAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Error while accepting the proposal.`
  String get proposalAcceptError {
    return Intl.message(
      'Error while accepting the proposal.',
      name: 'proposalAcceptError',
      desc: '',
      args: [],
    );
  }

  /// `Proposal rejected.`
  String get proposalRejected {
    return Intl.message(
      'Proposal rejected.',
      name: 'proposalRejected',
      desc: '',
      args: [],
    );
  }

  /// `Error while rejecting the proposal.`
  String get proposalRejectError {
    return Intl.message(
      'Error while rejecting the proposal.',
      name: 'proposalRejectError',
      desc: '',
      args: [],
    );
  }

  /// `Sprints`
  String get sprints {
    return Intl.message('Sprints', name: 'sprints', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Clear Conversation?`
  String get clearConversationTitle {
    return Intl.message(
      'Clear Conversation?',
      name: 'clearConversationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear all messages? This action cannot be undone.`
  String get clearConversationContent {
    return Intl.message(
      'Are you sure you want to clear all messages? This action cannot be undone.',
      name: 'clearConversationContent',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `Chat Assistant`
  String get chatAssistant {
    return Intl.message(
      'Chat Assistant',
      name: 'chatAssistant',
      desc: '',
      args: [],
    );
  }

  /// `Clear conversation`
  String get clearConversationTooltip {
    return Intl.message(
      'Clear conversation',
      name: 'clearConversationTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Conversations`
  String get conversations {
    return Intl.message(
      'Conversations',
      name: 'conversations',
      desc: '',
      args: [],
    );
  }

  /// `Checkout failed. Please try again.`
  String get subscriptionCheckoutFailed {
    return Intl.message(
      'Checkout failed. Please try again.',
      name: 'subscriptionCheckoutFailed',
      desc: '',
      args: [],
    );
  }

  /// `Login required to subscribe.`
  String get subscriptionLoginRequired {
    return Intl.message(
      'Login required to subscribe.',
      name: 'subscriptionLoginRequired',
      desc: '',
      args: [],
    );
  }

  /// `Subscription backend missing.`
  String get subscriptionBackendMissing {
    return Intl.message(
      'Subscription backend missing.',
      name: 'subscriptionBackendMissing',
      desc: '',
      args: [],
    );
  }

  /// `Choose your subscription plan.`
  String get subscriptionPlansIntro {
    return Intl.message(
      'Choose your subscription plan.',
      name: 'subscriptionPlansIntro',
      desc: '',
      args: [],
    );
  }

  /// `Active Plan`
  String get subscriptionActiveBadge {
    return Intl.message(
      'Active Plan',
      name: 'subscriptionActiveBadge',
      desc: '',
      args: [],
    );
  }

  /// `Yearly`
  String get subscriptionYearly {
    return Intl.message(
      'Yearly',
      name: 'subscriptionYearly',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get subscriptionMonthly {
    return Intl.message(
      'Monthly',
      name: 'subscriptionMonthly',
      desc: '',
      args: [],
    );
  }

  /// `Billed monthly`
  String get subscriptionBilledMonthly {
    return Intl.message(
      'Billed monthly',
      name: 'subscriptionBilledMonthly',
      desc: '',
      args: [],
    );
  }

  /// `Billed yearly`
  String get subscriptionBilledYearly {
    return Intl.message(
      'Billed yearly',
      name: 'subscriptionBilledYearly',
      desc: '',
      args: [],
    );
  }

  /// `Save 20% with yearly plan!`
  String get subscriptionYearlyPromoLine {
    return Intl.message(
      'Save 20% with yearly plan!',
      name: 'subscriptionYearlyPromoLine',
      desc: '',
      args: [],
    );
  }

  /// `Payment is handled securely.`
  String get subscriptionPaymentNote {
    return Intl.message(
      'Payment is handled securely.',
      name: 'subscriptionPaymentNote',
      desc: '',
      args: [],
    );
  }

  /// `Unlock premium features.`
  String get subscriptionSubtitle {
    return Intl.message(
      'Unlock premium features.',
      name: 'subscriptionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited access`
  String get subscriptionFeature1 {
    return Intl.message(
      'Unlimited access',
      name: 'subscriptionFeature1',
      desc: '',
      args: [],
    );
  }

  /// `Priority support`
  String get subscriptionFeature2 {
    return Intl.message(
      'Priority support',
      name: 'subscriptionFeature2',
      desc: '',
      args: [],
    );
  }

  /// `Early feature access`
  String get subscriptionFeature3 {
    return Intl.message(
      'Early feature access',
      name: 'subscriptionFeature3',
      desc: '',
      args: [],
    );
  }

  /// `Weak`
  String get weak {
    return Intl.message('Weak', name: 'weak', desc: '', args: []);
  }

  /// `Medium`
  String get medium {
    return Intl.message('Medium', name: 'medium', desc: '', args: []);
  }

  /// `Strong`
  String get strong {
    return Intl.message('Strong', name: 'strong', desc: '', args: []);
  }

  /// `Passwords do not match.`
  String get passwordsDoNotMatch {
    return Intl.message(
      'Passwords do not match.',
      name: 'passwordsDoNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `Password is too weak.`
  String get passwordTooWeak {
    return Intl.message(
      'Password is too weak.',
      name: 'passwordTooWeak',
      desc: '',
      args: [],
    );
  }

  /// `Password updated successfully.`
  String get passwordUpdated {
    return Intl.message(
      'Password updated successfully.',
      name: 'passwordUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Failed to change password.`
  String get failedToChangePassword {
    return Intl.message(
      'Failed to change password.',
      name: 'failedToChangePassword',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get changePassword {
    return Intl.message(
      'Change Password',
      name: 'changePassword',
      desc: '',
      args: [],
    );
  }

  /// `Create a strong password`
  String get createStrongPassword {
    return Intl.message(
      'Create a strong password',
      name: 'createStrongPassword',
      desc: '',
      args: [],
    );
  }

  /// `Current Password`
  String get currentPassword {
    return Intl.message(
      'Current Password',
      name: 'currentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter your current password`
  String get enterCurrentPassword {
    return Intl.message(
      'Enter your current password',
      name: 'enterCurrentPassword',
      desc: '',
      args: [],
    );
  }

  /// `New Password`
  String get newPassword {
    return Intl.message(
      'New Password',
      name: 'newPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter your new password`
  String get enterNewPassword {
    return Intl.message(
      'Enter your new password',
      name: 'enterNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password strength: `
  String get passwordStrength {
    return Intl.message(
      'Password strength: ',
      name: 'passwordStrength',
      desc: '',
      args: [],
    );
  }

  /// `Confirm New Password`
  String get confirmNewPassword {
    return Intl.message(
      'Confirm New Password',
      name: 'confirmNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Re-enter your new password`
  String get confirmNewPasswordHint {
    return Intl.message(
      'Re-enter your new password',
      name: 'confirmNewPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `Passwords match!`
  String get passwordsMatch {
    return Intl.message(
      'Passwords match!',
      name: 'passwordsMatch',
      desc: '',
      args: [],
    );
  }

  /// `Password requirements:`
  String get passwordRequirements {
    return Intl.message(
      'Password requirements:',
      name: 'passwordRequirements',
      desc: '',
      args: [],
    );
  }

  /// `At least 8 characters`
  String get atLeast8Chars {
    return Intl.message(
      'At least 8 characters',
      name: 'atLeast8Chars',
      desc: '',
      args: [],
    );
  }

  /// `Upper and lower case letters`
  String get upperLowerCase {
    return Intl.message(
      'Upper and lower case letters',
      name: 'upperLowerCase',
      desc: '',
      args: [],
    );
  }

  /// `At least one number`
  String get atLeastOneNumber {
    return Intl.message(
      'At least one number',
      name: 'atLeastOneNumber',
      desc: '',
      args: [],
    );
  }

  /// `At least one special character`
  String get atLeastOneSpecial {
    return Intl.message(
      'At least one special character',
      name: 'atLeastOneSpecial',
      desc: '',
      args: [],
    );
  }

  /// `Update Password`
  String get updatePassword {
    return Intl.message(
      'Update Password',
      name: 'updatePassword',
      desc: '',
      args: [],
    );
  }

  /// `Premium Feature`
  String get premiumFeature {
    return Intl.message(
      'Premium Feature',
      name: 'premiumFeature',
      desc: '',
      args: [],
    );
  }

  /// `Mon`
  String get monShort {
    return Intl.message('Mon', name: 'monShort', desc: '', args: []);
  }

  /// `Tue`
  String get tueShort {
    return Intl.message('Tue', name: 'tueShort', desc: '', args: []);
  }

  /// `Wed`
  String get wedShort {
    return Intl.message('Wed', name: 'wedShort', desc: '', args: []);
  }

  /// `Thu`
  String get thuShort {
    return Intl.message('Thu', name: 'thuShort', desc: '', args: []);
  }

  /// `Fri`
  String get friShort {
    return Intl.message('Fri', name: 'friShort', desc: '', args: []);
  }

  /// `Sat`
  String get satShort {
    return Intl.message('Sat', name: 'satShort', desc: '', args: []);
  }

  /// `Sun`
  String get sunShort {
    return Intl.message('Sun', name: 'sunShort', desc: '', args: []);
  }

  /// `Jan`
  String get janShort {
    return Intl.message('Jan', name: 'janShort', desc: '', args: []);
  }

  /// `Feb`
  String get febShort {
    return Intl.message('Feb', name: 'febShort', desc: '', args: []);
  }

  /// `Mar`
  String get marShort {
    return Intl.message('Mar', name: 'marShort', desc: '', args: []);
  }

  /// `Apr`
  String get aprShort {
    return Intl.message('Apr', name: 'aprShort', desc: '', args: []);
  }

  /// `May`
  String get mayShort {
    return Intl.message('May', name: 'mayShort', desc: '', args: []);
  }

  /// `Jun`
  String get junShort {
    return Intl.message('Jun', name: 'junShort', desc: '', args: []);
  }

  /// `Jul`
  String get julShort {
    return Intl.message('Jul', name: 'julShort', desc: '', args: []);
  }

  /// `Aug`
  String get augShort {
    return Intl.message('Aug', name: 'augShort', desc: '', args: []);
  }

  /// `Sep`
  String get sepShort {
    return Intl.message('Sep', name: 'sepShort', desc: '', args: []);
  }

  /// `Oct`
  String get octShort {
    return Intl.message('Oct', name: 'octShort', desc: '', args: []);
  }

  /// `Nov`
  String get novShort {
    return Intl.message('Nov', name: 'novShort', desc: '', args: []);
  }

  /// `Dec`
  String get decShort {
    return Intl.message('Dec', name: 'decShort', desc: '', args: []);
  }

  /// `User`
  String get user {
    return Intl.message('User', name: 'user', desc: '', args: []);
  }

  /// `You're up to date!`
  String get upToDate {
    return Intl.message(
      'You\'re up to date!',
      name: 'upToDate',
      desc: '',
      args: [],
    );
  }

  /// `Daily Summary`
  String get dailySummary {
    return Intl.message(
      'Daily Summary',
      name: 'dailySummary',
      desc: '',
      args: [],
    );
  }

  /// `You have one important meeting, two emails that need attention, and a time gap this afternoon that could be optimized.`
  String get dailySummaryDesc {
    return Intl.message(
      'You have one important meeting, two emails that need attention, and a time gap this afternoon that could be optimized.',
      name: 'dailySummaryDesc',
      desc: '',
      args: [],
    );
  }

  /// `Team meeting at 10:00`
  String get teamMeeting {
    return Intl.message(
      'Team meeting at 10:00',
      name: 'teamMeeting',
      desc: '',
      args: [],
    );
  }

  /// `Urgent email from HR`
  String get urgentEmail {
    return Intl.message(
      'Urgent email from HR',
      name: 'urgentEmail',
      desc: '',
      args: [],
    );
  }

  /// `Free time between 15:00–16:30`
  String get freeTime {
    return Intl.message(
      'Free time between 15:00–16:30',
      name: 'freeTime',
      desc: '',
      args: [],
    );
  }

  /// `Summarized Emails`
  String get summarizedEmails {
    return Intl.message(
      'Summarized Emails',
      name: 'summarizedEmails',
      desc: '',
      args: [],
    );
  }

  /// `My Business`
  String get myBusiness {
    return Intl.message('My Business', name: 'myBusiness', desc: '', args: []);
  }

  /// `Book a Ride`
  String get bookARide {
    return Intl.message('Book a Ride', name: 'bookARide', desc: '', args: []);
  }

  /// `View Smart Suggestions`
  String get viewSmartSuggestions {
    return Intl.message(
      'View Smart Suggestions',
      name: 'viewSmartSuggestions',
      desc: '',
      args: [],
    );
  }

  /// `View AI Activity`
  String get viewAIActivity {
    return Intl.message(
      'View AI Activity',
      name: 'viewAIActivity',
      desc: '',
      args: [],
    );
  }

  /// `Smart Actions Hub`
  String get smartActionsHub {
    return Intl.message(
      'Smart Actions Hub',
      name: 'smartActionsHub',
      desc: '',
      args: [],
    );
  }

  /// `Quick Actions`
  String get quickActions {
    return Intl.message(
      'Quick Actions',
      name: 'quickActions',
      desc: '',
      args: [],
    );
  }

  /// `Today is`
  String get todayIs {
    return Intl.message('Today is', name: 'todayIs', desc: '', args: []);
  }

  /// `Hello`
  String get hello {
    return Intl.message('Hello', name: 'hello', desc: '', args: []);
  }

  /// `Welcome`
  String get welcome {
    return Intl.message('Welcome', name: 'welcome', desc: '', args: []);
  }

  /// `Change language`
  String get change_language {
    return Intl.message(
      'Change language',
      name: 'change_language',
      desc: '',
      args: [],
    );
  }

  /// `Choose your language`
  String get choose_language {
    return Intl.message(
      'Choose your language',
      name: 'choose_language',
      desc: '',
      args: [],
    );
  }

  /// `French`
  String get french {
    return Intl.message('French', name: 'french', desc: '', args: []);
  }

  /// `Arabic`
  String get arabic {
    return Intl.message('Arabic', name: 'arabic', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message('Dark Mode', name: 'darkMode', desc: '', args: []);
  }

  /// `Edit Profile`
  String get editProfile {
    return Intl.message(
      'Edit Profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Premium & Subscription`
  String get premiumSubscription {
    return Intl.message(
      'Premium & Subscription',
      name: 'premiumSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Privacy & Security`
  String get privacySecurity {
    return Intl.message(
      'Privacy & Security',
      name: 'privacySecurity',
      desc: '',
      args: [],
    );
  }

  /// `Help & Support`
  String get helpSupport {
    return Intl.message(
      'Help & Support',
      name: 'helpSupport',
      desc: '',
      args: [],
    );
  }

  /// `Log Out`
  String get logOut {
    return Intl.message('Log Out', name: 'logOut', desc: '', args: []);
  }

  /// `Hello! How can I help you today?`
  String get helloHowCanIHelp {
    return Intl.message(
      'Hello! How can I help you today?',
      name: 'helloHowCanIHelp',
      desc: '',
      args: [],
    );
  }

  /// `Talk to buddy`
  String get talkToBuddy {
    return Intl.message(
      'Talk to buddy',
      name: 'talkToBuddy',
      desc: '',
      args: [],
    );
  }

  /// `Go ahead, I'm listening...`
  String get listeningPrompt {
    return Intl.message(
      'Go ahead, I\'m listening...',
      name: 'listeningPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Thinking...`
  String get thinkingPrompt {
    return Intl.message(
      'Thinking...',
      name: 'thinkingPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Ready to help with`
  String get readyToHelp {
    return Intl.message(
      'Ready to help with',
      name: 'readyToHelp',
      desc: '',
      args: [],
    );
  }

  /// `everything you need today!`
  String get everythingYouNeedToday {
    return Intl.message(
      'everything you need today!',
      name: 'everythingYouNeedToday',
      desc: '',
      args: [],
    );
  }

  /// `Enter your prompt here...`
  String get enterPromptHere {
    return Intl.message(
      'Enter your prompt here...',
      name: 'enterPromptHere',
      desc: '',
      args: [],
    );
  }

  /// `History`
  String get history {
    return Intl.message('History', name: 'history', desc: '', args: []);
  }

  /// `Welcome back!`
  String get welcomeBack {
    return Intl.message(
      'Welcome back!',
      name: 'welcomeBack',
      desc: '',
      args: [],
    );
  }

  /// `Features`
  String get features {
    return Intl.message('Features', name: 'features', desc: '', args: []);
  }

  /// `Get suggestions and tips to maximize your experience.`
  String get suggestions {
    return Intl.message(
      'Get suggestions and tips to maximize your experience.',
      name: 'suggestions',
      desc: '',
      args: [],
    );
  }

  /// `Sign up now!`
  String get signUp {
    return Intl.message('Sign up now!', name: 'signUp', desc: '', args: []);
  }

  /// `Already have an account? Log in.`
  String get signInSubtitle {
    return Intl.message(
      'Already have an account? Log in.',
      name: 'signInSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get createAccount {
    return Intl.message(
      'Create Account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get signInAction {
    return Intl.message('Sign In', name: 'signInAction', desc: '', args: []);
  }

  /// `Smart Replies`
  String get smartReplies {
    return Intl.message(
      'Smart Replies',
      name: 'smartReplies',
      desc: '',
      args: [],
    );
  }

  /// `Get instant suggestions for your conversations.`
  String get smartRepliesDesc {
    return Intl.message(
      'Get instant suggestions for your conversations.',
      name: 'smartRepliesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Calendar Sync`
  String get calendarSync {
    return Intl.message(
      'Calendar Sync',
      name: 'calendarSync',
      desc: '',
      args: [],
    );
  }

  /// `Sync your events and never miss anything.`
  String get calendarSyncDesc {
    return Intl.message(
      'Sync your events and never miss anything.',
      name: 'calendarSyncDesc',
      desc: '',
      args: [],
    );
  }

  /// `Private by Design`
  String get privateByDesign {
    return Intl.message(
      'Private by Design',
      name: 'privateByDesign',
      desc: '',
      args: [],
    );
  }

  /// `Your data is always safe and secure.`
  String get privateByDesignDesc {
    return Intl.message(
      'Your data is always safe and secure.',
      name: 'privateByDesignDesc',
      desc: '',
      args: [],
    );
  }

  /// `Days active`
  String get daysActive {
    return Intl.message('Days active', name: 'daysActive', desc: '', args: []);
  }

  /// `Hours saved`
  String get hoursSaved {
    return Intl.message('Hours saved', name: 'hoursSaved', desc: '', args: []);
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message('Dashboard', name: 'dashboard', desc: '', args: []);
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `Good morning`
  String get goodMorning {
    return Intl.message(
      'Good morning',
      name: 'goodMorning',
      desc: '',
      args: [],
    );
  }

  /// `Good afternoon`
  String get goodAfternoon {
    return Intl.message(
      'Good afternoon',
      name: 'goodAfternoon',
      desc: '',
      args: [],
    );
  }

  /// `Good evening`
  String get goodEvening {
    return Intl.message(
      'Good evening',
      name: 'goodEvening',
      desc: '',
      args: [],
    );
  }

  /// `Monday`
  String get monday {
    return Intl.message('Monday', name: 'monday', desc: '', args: []);
  }

  /// `Tuesday`
  String get tuesday {
    return Intl.message('Tuesday', name: 'tuesday', desc: '', args: []);
  }

  /// `Wednesday`
  String get wednesday {
    return Intl.message('Wednesday', name: 'wednesday', desc: '', args: []);
  }

  /// `Thursday`
  String get thursday {
    return Intl.message('Thursday', name: 'thursday', desc: '', args: []);
  }

  /// `Friday`
  String get friday {
    return Intl.message('Friday', name: 'friday', desc: '', args: []);
  }

  /// `Saturday`
  String get saturday {
    return Intl.message('Saturday', name: 'saturday', desc: '', args: []);
  }

  /// `Sunday`
  String get sunday {
    return Intl.message('Sunday', name: 'sunday', desc: '', args: []);
  }

  /// `January`
  String get january {
    return Intl.message('January', name: 'january', desc: '', args: []);
  }

  /// `February`
  String get february {
    return Intl.message('February', name: 'february', desc: '', args: []);
  }

  /// `March`
  String get march {
    return Intl.message('March', name: 'march', desc: '', args: []);
  }

  /// `April`
  String get april {
    return Intl.message('April', name: 'april', desc: '', args: []);
  }

  /// `May`
  String get may {
    return Intl.message('May', name: 'may', desc: '', args: []);
  }

  /// `June`
  String get june {
    return Intl.message('June', name: 'june', desc: '', args: []);
  }

  /// `July`
  String get july {
    return Intl.message('July', name: 'july', desc: '', args: []);
  }

  /// `August`
  String get august {
    return Intl.message('August', name: 'august', desc: '', args: []);
  }

  /// `September`
  String get september {
    return Intl.message('September', name: 'september', desc: '', args: []);
  }

  /// `October`
  String get october {
    return Intl.message('October', name: 'october', desc: '', args: []);
  }

  /// `November`
  String get november {
    return Intl.message('November', name: 'november', desc: '', args: []);
  }

  /// `December`
  String get december {
    return Intl.message('December', name: 'december', desc: '', args: []);
  }

  /// `Investor Meeting`
  String get investorMeeting {
    return Intl.message(
      'Investor Meeting',
      name: 'investorMeeting',
      desc: '',
      args: [],
    );
  }

  /// `Market Intelligence`
  String get marketIntelligence {
    return Intl.message(
      'Market Intelligence',
      name: 'marketIntelligence',
      desc: '',
      args: [],
    );
  }

  /// `Priority`
  String get priority {
    return Intl.message('Priority', name: 'priority', desc: '', args: []);
  }

  /// `Actions`
  String get actions {
    return Intl.message('Actions', name: 'actions', desc: '', args: []);
  }

  /// `Deadlines`
  String get deadlines {
    return Intl.message('Deadlines', name: 'deadlines', desc: '', args: []);
  }

  /// `Low`
  String get low {
    return Intl.message('Low', name: 'low', desc: '', args: []);
  }

  /// `High`
  String get high {
    return Intl.message('High', name: 'high', desc: '', args: []);
  }

  /// `View All Emails`
  String get viewAllEmails {
    return Intl.message(
      'View All Emails',
      name: 'viewAllEmails',
      desc: '',
      args: [],
    );
  }

  /// `Challenges & Rewards`
  String get challengesAndRewards {
    return Intl.message(
      'Challenges & Rewards',
      name: 'challengesAndRewards',
      desc: '',
      args: [],
    );
  }

  /// `Challenges`
  String get challengesTab {
    return Intl.message(
      'Challenges',
      name: 'challengesTab',
      desc: '',
      args: [],
    );
  }

  /// `Leaderboard`
  String get leaderboardTab {
    return Intl.message(
      'Leaderboard',
      name: 'leaderboardTab',
      desc: '',
      args: [],
    );
  }

  /// `Your Points`
  String get yourPoints {
    return Intl.message('Your Points', name: 'yourPoints', desc: '', args: []);
  }

  /// `Rank`
  String get rank {
    return Intl.message('Rank', name: 'rank', desc: '', args: []);
  }

  /// `Syncing challenge status from system...`
  String get syncingChallengeStatus {
    return Intl.message(
      'Syncing challenge status from system...',
      name: 'syncingChallengeStatus',
      desc: '',
      args: [],
    );
  }

  /// `Progression: {completed} / {total} completed`
  String progressionCompleted(Object completed, Object total) {
    return Intl.message(
      'Progression: $completed / $total completed',
      name: 'progressionCompleted',
      desc: '',
      args: [completed, total],
    );
  }

  /// `Loading challenges...`
  String get loadingChallenges {
    return Intl.message(
      'Loading challenges...',
      name: 'loadingChallenges',
      desc: '',
      args: [],
    );
  }

  /// `Loading leaderboard...`
  String get loadingLeaderboard {
    return Intl.message(
      'Loading leaderboard...',
      name: 'loadingLeaderboard',
      desc: '',
      args: [],
    );
  }

  /// `Locked Challenge #{number}`
  String lockedChallenge(Object number) {
    return Intl.message(
      'Locked Challenge #$number',
      name: 'lockedChallenge',
      desc: '',
      args: [number],
    );
  }

  /// `Finish the previous challenge to unlock this mission`
  String get finishPreviousChallenge {
    return Intl.message(
      'Finish the previous challenge to unlock this mission',
      name: 'finishPreviousChallenge',
      desc: '',
      args: [],
    );
  }

  /// `locked`
  String get locked {
    return Intl.message('locked', name: 'locked', desc: '', args: []);
  }

  /// `pts`
  String get pts {
    return Intl.message('pts', name: 'pts', desc: '', args: []);
  }

  /// `Complete previous challenge to unlock this one.`
  String get completePreviousChallenge {
    return Intl.message(
      'Complete previous challenge to unlock this one.',
      name: 'completePreviousChallenge',
      desc: '',
      args: [],
    );
  }

  /// `Steps to Complete:`
  String get stepsToComplete {
    return Intl.message(
      'Steps to Complete:',
      name: 'stepsToComplete',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get completed {
    return Intl.message('Completed', name: 'completed', desc: '', args: []);
  }

  /// `+{points} points`
  String pointsWithPlus(Object points) {
    return Intl.message(
      '+$points points',
      name: 'pointsWithPlus',
      desc: '',
      args: [points],
    );
  }

  /// `Voice`
  String get voice {
    return Intl.message('Voice', name: 'voice', desc: '', args: []);
  }

  /// `Premium`
  String get premium {
    return Intl.message('Premium', name: 'premium', desc: '', args: []);
  }

  /// `Monthly Champion`
  String get monthlyChampion {
    return Intl.message(
      'Monthly Champion',
      name: 'monthlyChampion',
      desc: '',
      args: [],
    );
  }

  /// `Pro`
  String get pro {
    return Intl.message('Pro', name: 'pro', desc: '', args: []);
  }

  /// `{count} challenges completed`
  String challengesCompleted(Object count) {
    return Intl.message(
      '$count challenges completed',
      name: 'challengesCompleted',
      desc: '',
      args: [count],
    );
  }

  /// `points`
  String get points {
    return Intl.message('points', name: 'points', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
