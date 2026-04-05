import 'package:shared_preferences/shared_preferences.dart';

const String _kUserId = 'ava_wellbeing_user_id';
const String _kAnchorDay = 'ava_wellbeing_anchor_day';
const String _kLastScore = 'ava_wellbeing_last_score';
const String _kLastSubmitMonth = 'ava_wellbeing_last_submit_yyyymm';

class WellbeingStorage {
  WellbeingStorage._();

  static Future<String?> userId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kUserId);
  }

  static Future<void> setUserId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUserId, id);
  }

  static Future<int?> anchorDay() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kAnchorDay);
  }

  static Future<void> setAnchorDay(int day) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kAnchorDay, day.clamp(1, 28));
  }

  /// Après 404 Nest sur `/api/wellbeing/status` (user_id inconnu).
  static Future<void> clearWellbeingIdentity() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kUserId);
    await p.remove(_kAnchorDay);
  }

  static Future<double?> lastScore0to100() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kLastScore);
  }

  static Future<void> setLastScore(double score) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLastScore, score);
  }

  static Future<int?> lastSubmitYyyymm() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kLastSubmitMonth);
  }

  static Future<void> setLastSubmitYyyymm(int yyyymm) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastSubmitMonth, yyyymm);
  }

  /// Simple local gate: one full diagnostic per calendar month (YYYY × 100 + MM).
  static Future<bool> localMonthlyAllowed() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getInt(_kLastSubmitMonth);
    if (last == null) return true;
    final now = DateTime.now();
    final current = now.year * 100 + now.month;
    return last < current;
  }
}
