import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'app_theme_mode';

/// Service de thème: persiste le mode et notifie l'app pour rebuild global.
class ThemeService {
  ThemeService._();
  static final ThemeService _instance = ThemeService._();
  static ThemeService get instance => _instance;

  final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );
  ValueListenable<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);
    _themeModeNotifier.value = _themeModeFromStorage(value);
  }

  ThemeMode get themeMode => _themeModeNotifier.value;

  bool get isDarkMode => _themeModeNotifier.value == ThemeMode.dark;

  Future<void> setDarkMode(bool enabled) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeModeToStorage(mode));
    _themeModeNotifier.value = mode;
  }

  ThemeMode _themeModeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
