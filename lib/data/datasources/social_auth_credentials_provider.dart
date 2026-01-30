import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/services/social_auth_credentials_provider.dart' as domain;

class DefaultSocialAuthCredentialsProvider
    implements domain.SocialAuthCredentialsProvider {
  DefaultSocialAuthCredentialsProvider({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> getGoogleIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
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
