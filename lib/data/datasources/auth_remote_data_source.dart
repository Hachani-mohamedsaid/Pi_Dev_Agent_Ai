import 'package:flutter/foundation.dart' show kIsWeb;
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
  }

  @override
  Future<void> resetPassword(String email) async {
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
    }
  }

  @override
  Future<UserModel> loginWithApple() async {
    // Sign in with Apple is not available on web
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
      return UserModel(
        id: userId,
        name: credential.givenName != null && credential.familyName != null
            ? '${credential.givenName} ${credential.familyName}'
            : credential.email?.split('@').first ?? 'Apple User',
        email: credential.email ?? '$userId@privaterelay.appleid.com',
      );
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }
}
