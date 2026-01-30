import '../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../services/social_auth_credentials_provider.dart';

class SocialLoginUseCase implements AsyncUseCase<User, SocialLoginParams> {
  SocialLoginUseCase(this._repository, this._credentialsProvider);

  final AuthRepository _repository;
  final SocialAuthCredentialsProvider _credentialsProvider;

  @override
  Future<User> call(SocialLoginParams params) async {
    switch (params.provider) {
      case SocialProvider.google:
        final idToken = await _credentialsProvider.getGoogleIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Google sign-in was cancelled or no idToken');
        }
        return await _repository.loginWithGoogle(idToken);
      case SocialProvider.apple:
        final creds = await _credentialsProvider.getAppleCredentials();
        if (creds == null) {
          throw Exception('Apple sign-in was cancelled or no credentials');
        }
        return await _repository.loginWithApple(
          creds.identityToken,
          user: creds.user,
        );
    }
  }
}

class SocialLoginParams {
  const SocialLoginParams({required this.provider});

  final SocialProvider provider;
}

enum SocialProvider {
  google,
  apple,
}
