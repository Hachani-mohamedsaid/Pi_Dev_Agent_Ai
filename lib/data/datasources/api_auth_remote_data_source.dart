import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/auth_response.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Implémentation HTTP des endpoints auth (NestJS). Utilise [apiBaseUrl].
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource({String? baseUrl}) : _baseUrl = baseUrl ?? apiBaseUrl;

  final String _baseUrl;

  static const _headers = {'Content-Type': 'application/json'};

  @override
  Future<AuthResponse> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _parseError(res);
  }

  @override
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode == 201) {
      return AuthResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _parseError(res);
  }

  /// Demande reset mot de passe : le backend envoie l’email (Resend, etc.) avec le lien contenant le token.
  @override
  Future<void> resetPassword(String email) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) throw _parseError(res);
  }

  /// Définit le nouveau mot de passe avec le token reçu par email (lien « Reset Password »).
  @override
  Future<void> setNewPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password/confirm'),
      headers: _headers,
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    if (res.statusCode != 200) throw _parseError(res);
  }

  @override
  Future<void> changePassword(
    String accessToken, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) throw _parseError(res);
  }

  @override
  Future<void> requestEmailVerification(String accessToken) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/verify-email'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw _parseError(res);
  }

  @override
  Future<void> confirmEmailVerification(String token) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/verify-email/confirm'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw _parseError(res);
  }

  /// Connexion Google : envoie l'idToken obtenu côté Flutter (web/mobile) au backend NestJS.
  /// Backend attend POST /auth/google avec body { "idToken": "..." } et renvoie { user, accessToken }.
  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: _headers,
      body: jsonEncode({'idToken': idToken}),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _parseError(res);
  }

  @override
  Future<AuthResponse> loginWithApple(
    String identityToken, {
    String? user,
  }) async {
    final body = <String, dynamic>{'identityToken': identityToken};
    if (user != null) body['user'] = user;
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/apple'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _parseError(res);
  }

  @override
  Future<ProfileModel> getProfile(String accessToken) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode == 200) {
      return ProfileModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _parseError(res);
  }

  @override
  Future<void> updateProfile(
    String accessToken, {
    String? name,
    String? avatarUrl,
    String? role,
    String? location,
    String? phone,
    String? birthDate,
    String? bio,
    int? conversationsCount,
    int? hoursSaved,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (role != null) body['role'] = role;
    if (location != null) body['location'] = location;
    if (phone != null) body['phone'] = phone;
    if (birthDate != null) body['birthDate'] = birthDate;
    if (bio != null) body['bio'] = bio;
    if (conversationsCount != null)
      body['conversationsCount'] = conversationsCount;
    if (hoursSaved != null) body['hoursSaved'] = hoursSaved;

    final res = await http.patch(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) throw _parseError(res);
  }

  @override
  Future<bool> checkHealth() async {
    final res = await http.get(Uri.parse('$_baseUrl/health'));
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    return data?['status'] == 'ok';
  }

  Exception _parseError(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final msg = data?['message'];
      if (msg is List) return Exception(msg.join(', '));
      return Exception(msg?.toString() ?? 'Request failed');
    } catch (_) {
      return Exception('Request failed (${res.statusCode})');
    }
  }
}
