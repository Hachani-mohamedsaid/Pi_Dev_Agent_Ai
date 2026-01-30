import '../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
<<<<<<< HEAD

class SocialLoginUseCase implements AsyncUseCase<User, SocialLoginParams> {
  const SocialLoginUseCase(this._repository);

  final AuthRepository _repository;
=======
import '../services/social_auth_credentials_provider.dart';

class SocialLoginUseCase implements AsyncUseCase<User, SocialLoginParams> {
  const SocialLoginUseCase(
    this._repository,
    this._credentialsProvider,
  );

  final AuthRepository _repository;
  final SocialAuthCredentialsProvider _credentialsProvider;
>>>>>>> c3cf2c9 ( Flutter project v1)

  @override
  Future<User> call(SocialLoginParams params) async {
    switch (params.provider) {
      case SocialProvider.google:
<<<<<<< HEAD
        return await _repository.loginWithGoogle();
      case SocialProvider.apple:
        return await _repository.loginWithApple();
=======
        final idToken = await _credentialsProvider.getGoogleIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Google sign-in was cancelled or no idToken');
        }
        return await _repository.loginWithGoogle(idToken);
      case SocialProvider.apple:
        final cred = await _credentialsProvider.getAppleCredentials();
        if (cred == null) {
          throw Exception('Apple sign-in was cancelled or no credential');
        }
        return await _repository.loginWithApple(
          cred.identityToken,
          user: cred.user,
        );
>>>>>>> c3cf2c9 ( Flutter project v1)
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
