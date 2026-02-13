import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyLocale = 'app_locale';

/// Service de langue : persiste le code (en, fr, ...) et notifie l'app pour rebuild.
class LocaleService {
  LocaleService._();
  static final LocaleService _instance = LocaleService._();
  static LocaleService get instance => _instance;

  final ValueNotifier<Locale?> _localeNotifier = ValueNotifier<Locale?>(null);
  ValueListenable<Locale?> get localeNotifier => _localeNotifier;

  /// Charge la langue sauvegardée (à appeler au démarrage).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLocale);
    if (code != null && code.isNotEmpty) {
      _localeNotifier.value = Locale(code);
    } else {
      _localeNotifier.value = const Locale('en');
    }
  }

  /// Retourne la locale actuelle (après load).
  Locale get locale => _localeNotifier.value ?? const Locale('en');

  /// Change la langue et persiste. L'app se reconstruit via ValueListenable.
  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, languageCode);
    _localeNotifier.value = Locale(languageCode);
  }

  /// Code langue actuel (en, fr, ...).
  String get languageCode => _localeNotifier.value?.languageCode ?? 'en';
}
