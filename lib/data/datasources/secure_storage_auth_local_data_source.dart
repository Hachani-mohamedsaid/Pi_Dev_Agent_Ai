import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_local_data_source.dart';

/// Persiste le token et l'utilisateur dans flutter_secure_storage (keychain
/// sur iOS) pour survivre au redémarrage / refresh.
///
/// Le token et l'ID utilisateur sont également mirrorés dans SharedPreferences
/// (mêmes clés que [SharedPreferencesAuthLocalDataSource]) pour rester
/// compatibles avec les pages legacy qui lisent directement les prefs.
class SecureStorageAuthLocalDataSource implements AuthLocalDataSource {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyCachedUser = 'auth_cached_user';
  static const _keyUserIdMirror = 'user_id';
  static const _legacySubscriptionPlanKey = 'subscription_active_plan';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> cacheUser(UserModel user) async {
    final json = jsonEncode(user.toJson());
    await _storage.write(key: _keyCachedUser, value: json);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedUser, json);
    if (user.id.isNotEmpty) {
      await prefs.setString(_keyUserIdMirror, user.id);
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final json = await _storage.read(key: _keyCachedUser);
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyCachedUser);
    await _storage.delete(key: _legacySubscriptionPlanKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyCachedUser);
    await prefs.remove(_keyUserIdMirror);
    await prefs.remove(_legacySubscriptionPlanKey);
  }

  @override
  Future<String?> getUserId() async {
    final user = await getCachedUser();
    return user?.id;
  }

  @override
  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _keyAccessToken);
    // Self-heal: if the token exists in keychain but not in SharedPreferences
    // (legacy users from before the mirror was added), copy it across so the
    // pages that read directly from SharedPreferences keep working.
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_keyAccessToken) != token) {
        await prefs.setString(_keyAccessToken, token);
      }
    }
    return token;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
  }
}
