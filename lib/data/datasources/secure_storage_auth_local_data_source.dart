import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'auth_local_data_source.dart';

/// Persiste le token et l'utilisateur dans flutter_secure_storage pour survivre au redémarrage / refresh.
class SecureStorageAuthLocalDataSource implements AuthLocalDataSource {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyCachedUser = 'auth_cached_user';
  static const _legacySubscriptionPlanKey = 'subscription_active_plan';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> cacheUser(UserModel user) async {
    await _storage.write(key: _keyCachedUser, value: jsonEncode(user.toJson()));
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
  }

  @override
  Future<String?> getUserId() async {
    final user = await getCachedUser();
    return user?.id;
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }
}
