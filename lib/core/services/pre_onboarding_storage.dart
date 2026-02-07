import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for pre-login onboarding completion.
/// Independent from post-login onboarding - do not reuse.
class PreOnboardingStorage {
  PreOnboardingStorage._();

  static const _keyHasSeenPreOnboarding = 'hasSeenPreOnboarding';

  /// Whether the user has completed the pre-login onboarding.
  static Future<bool> get hasSeenPreOnboarding async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenPreOnboarding) ?? false;
  }

  /// Mark pre-login onboarding as seen. Call when user completes intro flow.
  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenPreOnboarding, true);
  }
}
