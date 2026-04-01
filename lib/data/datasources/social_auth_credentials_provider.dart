import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/services/social_auth_credentials_provider.dart' as domain;

class DefaultSocialAuthCredentialsProvider
    implements domain.SocialAuthCredentialsProvider {
  DefaultSocialAuthCredentialsProvider({
    String? webClientId,
    String? iosClientId,
  }) : _webClientId = webClientId,
       _iosClientId = iosClientId;

  final String? _webClientId;
  final String? _iosClientId;

  Future<String> _authenticateAndGetIdToken() async {
    final account = await GoogleSignIn.instance.authenticate();
    final auth = account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google Sign-In n\'a pas retourne de idToken. Verifie la config OAuth.',
      );
    }
    return idToken;
  }

  @override
  Future<String?> getGoogleIdToken() async {
    if (kIsWeb && (_webClientId?.trim().isEmpty ?? true)) {
      throw Exception(
        'Google Sign-In non configuré. Ajoute ton Web Client ID dans '
        'lib/core/config/google_oauth_config.dart et dans web/index.html '
        '(meta google-signin-client_id). Voir la console Google Cloud.',
      );
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        (_iosClientId?.trim().isEmpty ?? true)) {
      throw Exception(
        'Google iOS mal configuré: CLIENT_ID iOS manquant. '
        'Ajoute le CLIENT_ID iOS (pas Web) dans lib/core/config/google_oauth_config.dart '
        'et GOOGLE_IOS_CLIENT_ID / GOOGLE_REVERSED_CLIENT_ID dans ios/Flutter/*.xcconfig.',
      );
    }
    // 7.x : authenticate() au lieu de signIn() ; sur le web on utilise renderButton + authenticationEvents.
    try {
      return await _authenticateAndGetIdToken();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isUserCancel =
          msg.contains('cancel') ||
          msg.contains('canceled') ||
          msg.contains('cancelled');
      if (isUserCancel) {
        return null;
      }
      final isKeychainProviderConfigError =
          msg.contains('providerconfigurationerror') ||
          msg.contains('keychain error') ||
          msg.contains('nslocalizeddescription: keychain error');
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          isKeychainProviderConfigError) {
        try {
          await GoogleSignIn.instance.signOut();
          await Future<void>.delayed(const Duration(milliseconds: 250));
          return await _authenticateAndGetIdToken();
        } catch (_) {
          throw Exception(
            'Google Sign-In iOS: keychain error. Sur simulateur, execute '
            '"xcrun simctl erase all" puis relance l\'app. Si possible, teste sur appareil physique.',
          );
        }
      }
      rethrow;
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

    return domain.AppleAuthCredentials(identityToken: token, user: userJson);
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
