/// Credentials Apple à envoyer au backend (identityToken + user optionnel).
class AppleAuthCredentials {
  const AppleAuthCredentials({
    required this.identityToken,
    this.user,
  });

  final String identityToken;
  final String? user;
}

/// Fournit les tokens Google/Apple après sign-in natif (pour les envoyer au backend).
abstract class SocialAuthCredentialsProvider {
  Future<String?> getGoogleIdToken();
  Future<AppleAuthCredentials?> getAppleCredentials();
}
