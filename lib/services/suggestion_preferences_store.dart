import 'package:shared_preferences/shared_preferences.dart';

/// Persists accepted/dismissed suggestion feedback so the AI can learn user personality.
class SuggestionPreferencesStore {
  static const _keyAccepted = 'suggestion_prefs_accepted';
  static const _keyDismissed = 'suggestion_prefs_dismissed';
  static const _maxEntries = 12;

  /// Record that the user accepted a suggestion (type + message).
  static Future<void> addAccepted({required String type, required String message}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getList(prefs, _keyAccepted);
    list.add(_entry(type, message));
    await _saveList(prefs, _keyAccepted, list);
  }

  /// Record that the user dismissed a suggestion (type + message).
  static Future<void> addDismissed({required String type, required String message}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getList(prefs, _keyDismissed);
    list.add(_entry(type, message));
    await _saveList(prefs, _keyDismissed, list);
  }

  static String _entry(String type, String message) {
    final short = message.length > 50 ? '${message.substring(0, 47)}...' : message;
    return '$type:$short';
  }

  static List<String> _getList(SharedPreferences prefs, String key) {
    final raw = prefs.getStringList(key);
    if (raw == null) return [];
    return raw;
  }

  static Future<void> _saveList(SharedPreferences prefs, String key, List<String> list) async {
    final trimmed = list.length > _maxEntries ? list.sublist(list.length - _maxEntries) : list;
    await prefs.setStringList(key, trimmed);
  }

  /// Summary string for the AI so it can personalize (prefer accepted themes, avoid dismissed).
  static Future<String> getLearnedSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = _getList(prefs, _keyAccepted);
    final dismissed = _getList(prefs, _keyDismissed);
    if (accepted.isEmpty && dismissed.isEmpty) return '';
    final parts = <String>[];
    if (accepted.isNotEmpty) {
      final types = accepted.map((e) => e.split(':').first).toSet().join(', ');
      parts.add('User tends to accept: $types. Examples: ${accepted.take(5).join('; ')}.');
    }
    if (dismissed.isNotEmpty) {
      final types = dismissed.map((e) => e.split(':').first).toSet().join(', ');
      parts.add('User tends to refuse: $types. Examples: ${dismissed.take(5).join('; ')}.');
    }
    return parts.join(' ');
  }
}
