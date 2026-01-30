import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/auth_response.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Retourne user + accessToken (backend NestJS). En mock, accessToken peut être vide.
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String name, String email, String password);
  Future<void> resetPassword(String email);

  /// POST /auth/reset-password/confirm – nouveau MDP avec token du lien email.
  Future<void> setNewPassword({required String token, required String newPassword});

  /// POST /auth/change-password – changer le MDP (utilisateur connecté).
  Future<void> changePassword(String accessToken, {required String currentPassword, required String newPassword});

  /// idToken fourni par Google Sign-In, envoyé au backend.
  Future<AuthResponse> loginWithGoogle(String idToken);
  /// identityToken + user optionnel fournis par Sign in with Apple.
  Future<AuthResponse> loginWithApple(String identityToken, {String? user});

  /// GET /auth/me – profil avec stats (role, location, conversationsCount, etc.).
  Future<ProfileModel> getProfile(String accessToken);

  /// PATCH /auth/me – mise à jour du profil.
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
  });

  /// GET /health – vérifier que le backend répond.
  Future<bool> checkHealth();
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  Future<AuthResponse> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'User',
      email: email,
    );
    return AuthResponse(user: user, accessToken: '');
  }

  @override
  Future<AuthResponse> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
    return AuthResponse(user: user, accessToken: '');
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> setNewPassword({required String token, required String newPassword}) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }
      final user = UserModel(
        id: googleUser.id,
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
      );
      return AuthResponse(user: user, accessToken: '');
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  @override
  Future<AuthResponse> loginWithApple(String identityToken, {String? user}) async {
    if (kIsWeb) {
      throw Exception('Sign in with Apple is not available on web. Please use Google Sign-In or email/password.');
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final userId = credential.userIdentifier ?? 'apple_user_${DateTime.now().millisecondsSinceEpoch}';
      final profileUser = UserModel(
        id: userId,
        name: credential.givenName != null && credential.familyName != null
            ? '${credential.givenName} ${credential.familyName}'
            : credential.email?.split('@').first ?? 'Apple User',
        email: credential.email ?? '$userId@privaterelay.appleid.com',
      );
      return AuthResponse(user: profileUser, accessToken: '');
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  @override
  Future<ProfileModel> getProfile(String accessToken) {
    throw UnsupportedError('getProfile not supported with mock');
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
  }) async {}

  @override
  Future<void> changePassword(String accessToken, {required String currentPassword, required String newPassword}) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> checkHealth() async => true;
}
