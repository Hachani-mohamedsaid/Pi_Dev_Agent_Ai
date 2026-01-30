import '../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SocialLoginUseCase implements AsyncUseCase<User, SocialLoginParams> {
  const SocialLoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<User> call(SocialLoginParams params) async {
    switch (params.provider) {
      case SocialProvider.google:
        return await _repository.loginWithGoogle();
      case SocialProvider.apple:
        return await _repository.loginWithApple();
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
