import 'package:shared_preferences/shared_preferences.dart';

import '../../injection_container.dart';

class SubscriptionAccessService {
  static const _activePlanKeyPrefix = 'subscription_active_plan';
  static const _legacyActivePlanKey = 'subscription_active_plan';

  static Future<bool> hasActivePlanForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await InjectionContainer.instance.authLocalDataSource
        .getUserId();

    final key = (userId == null || userId.isEmpty)
        ? _legacyActivePlanKey
        : '$_activePlanKeyPrefix:$userId';

    final plan = prefs.getString(key);
    return plan == 'monthly' || plan == 'yearly';
  }
}
