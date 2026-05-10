import 'wellbeing_api_client.dart';
import 'wellbeing_storage.dart';

/// Crée un utilisateur wellbeing côté Nest (`POST /api/register`) ou identité locale de secours.
Future<void> ensureWellbeingIdentity(WellbeingApiClient api) async {
  final existing = await WellbeingStorage.userId();
  if (existing != null && existing.isNotEmpty) return;

  if (api.isConfigured) {
    final reg = await api.registerUser();
    if (reg != null && await _persistNestRegistration(reg)) return;
  }

  await WellbeingStorage.setUserId(
    'local_${DateTime.now().millisecondsSinceEpoch}',
  );
  await WellbeingStorage.setAnchorDay(DateTime.now().day.clamp(1, 28));
}

Future<bool> _persistNestRegistration(Map<String, dynamic> reg) async {
  final rawId = reg['id'] ?? reg['user_id'] ?? reg['userId'];
  final uid = rawId?.toString().trim() ?? '';
  if (uid.isEmpty) return false;

  await WellbeingStorage.setUserId(uid);

  final ad =
      reg['diagnostic_anchor_day'] ?? reg['anchor_day'] ?? reg['anchorDay'];
  if (ad is int) {
    await WellbeingStorage.setAnchorDay(ad);
  } else if (ad is num) {
    await WellbeingStorage.setAnchorDay(ad.toInt());
  }
  return true;
}
