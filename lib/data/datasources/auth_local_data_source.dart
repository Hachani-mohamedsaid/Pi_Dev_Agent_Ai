<<<<<<< HEAD
=======
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

>>>>>>> c3cf2c9 ( Flutter project v1)
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
<<<<<<< HEAD
=======

  /// JWT renvoyé par le backend après login/register.
  Future<void> saveAccessToken(String? token);
  Future<String?> getAccessToken();
>>>>>>> c3cf2c9 ( Flutter project v1)
}

class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  UserModel? _cachedUser;
<<<<<<< HEAD
=======
  String? _accessToken;
>>>>>>> c3cf2c9 ( Flutter project v1)

  @override
  Future<void> cacheUser(UserModel user) async {
    _cachedUser = user;
  }

  @override
  Future<UserModel?> getCachedUser() async {
    return _cachedUser;
  }

  @override
  Future<void> clearCache() async {
    _cachedUser = null;
<<<<<<< HEAD
=======
    _accessToken = null;
  }

  @override
  Future<void> saveAccessToken(String? token) async {
    _accessToken = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return _accessToken;
  }
}

/// Persiste user + token avec SharedPreferences (survit au redémarrage).
class SharedPreferencesAuthLocalDataSource implements AuthLocalDataSource {
  SharedPreferencesAuthLocalDataSource(this._prefs);

  final Future<SharedPreferences> Function() _prefs;

  static const _keyAccessToken = 'accessToken';
  static const _keyUserJson = 'user_json';

  Future<SharedPreferences> get prefs => _prefs();

  @override
  Future<void> cacheUser(UserModel user) async {
    final p = await prefs;
    await p.setString(_keyUserJson, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final p = await prefs;
    final raw = p.getString(_keyUserJson);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final p = await prefs;
    await p.remove(_keyAccessToken);
    await p.remove(_keyUserJson);
  }

  @override
  Future<void> saveAccessToken(String? token) async {
    final p = await prefs;
    if (token == null) {
      await p.remove(_keyAccessToken);
    } else {
      await p.setString(_keyAccessToken, token);
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final p = await prefs;
    return p.getString(_keyAccessToken);
>>>>>>> c3cf2c9 ( Flutter project v1)
  }
}
