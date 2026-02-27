import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks real focus time (app in foreground) and gates suggestion requests.
/// Only allow requesting suggestions after [focusMinutesThreshold] and no suggestion in last [cooldownMinutes].
class FocusSessionManager {
  FocusSessionManager._();
  static final FocusSessionManager instance = FocusSessionManager._();

  static const String _keyLastSuggestionTime = 'focus_last_suggestion_time';

  /// Minutes of focus required before we can show a suggestion. Use 1 for quick test, 30 for production.
  static const int focusMinutesThreshold = 1; // 30 for production
  static const int cooldownMinutes = 30;

  DateTime? _sessionStartTime;
  int _focusMinutes = 0;
  DateTime? _lastSuggestionTime;
  Timer? _timer;
  bool _isForeground = false;

  int get focusMinutes => _focusMinutes;

  /// Called when app becomes resumed (foreground).
  void onResume() {
    if (_isForeground) return;
    _isForeground = true;
    _sessionStartTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isForeground && _sessionStartTime != null) {
        _focusMinutes++;
      }
    });
  }

  /// Called when app becomes paused or inactive (background). Reset focus to 0 only when app is closed.
  void onPause() {
    if (!_isForeground) return;
    _isForeground = false;
    _timer?.cancel();
    _timer = null;
    _sessionStartTime = null;
    _focusMinutes = 0; // remise à zéro uniquement quand on ferme l'app
  }

  /// True on first entry (no suggestion shown yet) or when focus >= threshold and cooldown passed.
  Future<bool> shouldRequestSuggestion() async {
    await _loadLastSuggestionTime();
    if (_lastSuggestionTime == null) return true; // first time: show suggestion immediately
    if (_focusMinutes < focusMinutesThreshold) return false;
    final since = DateTime.now().difference(_lastSuggestionTime!).inMinutes;
    if (since < cooldownMinutes) return false;
    return true;
  }

  /// Call after showing suggestions (or after user accepted/refused). Saves time only; do NOT reset focus (reset only on app close).
  Future<void> markSuggestionShown() async {
    _lastSuggestionTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastSuggestionTime,
      _lastSuggestionTime!.toIso8601String(),
    );
  }

  Future<void> _loadLastSuggestionTime() async {
    if (_lastSuggestionTime != null) return;
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyLastSuggestionTime);
    if (s != null) {
      _lastSuggestionTime = DateTime.tryParse(s);
    }
  }

  /// For display: current focus minutes (real usage). Includes current session elapsed time so the value updates before the first 60s tick.
  int getFocusMinutes() {
    if (_isForeground && _sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!).inMinutes;
      return _focusMinutes + elapsed;
    }
    return _focusMinutes;
  }
}
