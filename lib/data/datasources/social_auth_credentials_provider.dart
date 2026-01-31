import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/services/social_auth_credentials_provider.dart' as domain;

class DefaultSocialAuthCredentialsProvider
    implements domain.SocialAuthCredentialsProvider {
  DefaultSocialAuthCredentialsProvider({
    String? webClientId,
  }) : _webClientId = webClientId;

  final String? _webClientId;

  @override
  Future<String?> getGoogleIdToken() async {
    if (kIsWeb && (_webClientId?.trim().isEmpty ?? true)) {
      throw Exception(
        'Google Sign-In non configuré. Ajoute ton Web Client ID dans '
        'lib/core/config/google_oauth_config.dart et dans web/index.html '
        '(meta google-signin-client_id). Voir la console Google Cloud.',
      );
    }
    // 7.x : authenticate() au lieu de signIn() ; sur le web on utilise renderButton + authenticationEvents.
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      return auth.idToken;
    } catch (_) {
      return null; // annulation ou erreur
    }
  }

  @override
  Future<domain.AppleAuthCredentials?> getAppleCredentials() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final token = credential.identityToken;
    if (token == null || token.isEmpty) return null;

    String? userJson;
    if (credential.givenName != null || credential.familyName != null) {
      userJson = _encodeAppleUser(
        givenName: credential.givenName,
        familyName: credential.familyName,
        email: credential.email,
      );
    }

    return domain.AppleAuthCredentials(
      identityToken: token,
      user: userJson,
    );
  }

  static String _encodeAppleUser({
    String? givenName,
    String? familyName,
    String? email,
  }) {
    final map = <String, dynamic>{};
    if (givenName != null) map['givenName'] = givenName;
    if (familyName != null) map['familyName'] = familyName;
    if (email != null) map['email'] = email;
    return jsonEncode(map);
  }
}
