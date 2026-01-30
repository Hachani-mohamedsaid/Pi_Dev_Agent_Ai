<<<<<<< HEAD
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> resetPassword(String email);
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithApple();
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock successful login
    return UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'User',
      email: email,
    );
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock successful registration
    return UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
=======
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String name, String email, String password);
  Future<void> resetPassword(String email);
  Future<void> confirmResetPassword(String token, String newPassword);
  Future<AuthResponse> loginWithGoogle(String idToken);
  Future<AuthResponse> loginWithApple(String identityToken, {String? user});
  Future<UserModel> getMe(String accessToken);
  Future<bool> checkHealth();
}

/// Appels réels vers le backend NestJS (Railway).
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource({String? serverBaseUrl})
      : baseUrl = serverBaseUrl ?? apiBaseUrl;

  final String baseUrl;

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid email or password');
    }
    final err = _parseError(response.body);
    throw Exception(err);
  }

  @override
  Future<AuthResponse> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 409) {
      throw Exception('Email already registered');
    }
    final err = _parseError(response.body);
    throw Exception(err);
>>>>>>> c3cf2c9 ( Flutter project v1)
  }

  @override
  Future<void> resetPassword(String email) async {
<<<<<<< HEAD
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      return UserModel(
        id: googleUser.id,
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
      );
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
=======
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response.body));
>>>>>>> c3cf2c9 ( Flutter project v1)
    }
  }

  @override
<<<<<<< HEAD
  Future<UserModel> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userId = credential.userIdentifier ?? 'apple_user_${DateTime.now().millisecondsSinceEpoch}';
      return UserModel(
        id: userId,
        name: credential.givenName != null && credential.familyName != null
            ? '${credential.givenName} ${credential.familyName}'
            : credential.email?.split('@').first ?? 'Apple User',
        email: credential.email ?? '$userId@privaterelay.appleid.com',
      );
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
=======
  Future<void> confirmResetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response.body));
    }
  }

  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid Google token');
    }
    throw Exception(_parseError(response.body));
  }

  @override
  Future<AuthResponse> loginWithApple(String identityToken, {String? user}) async {
    final body = <String, dynamic>{'identityToken': identityToken};
    if (user != null) body['user'] = user;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid Apple token');
    }
    throw Exception(_parseError(response.body));
  }

  @override
  Future<UserModel> getMe(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }
    throw Exception(_parseError(response.body));
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  String _parseError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final msg = map['message'];
      if (msg is List) return (msg).map((e) => e.toString()).join(', ');
      return msg?.toString() ?? 'Request failed';
    } catch (_) {
      return body.isNotEmpty ? body : 'Request failed';
>>>>>>> c3cf2c9 ( Flutter project v1)
    }
  }
}
