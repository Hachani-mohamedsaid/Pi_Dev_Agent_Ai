import '../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements AsyncUseCase<User, LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<User> call(LoginParams params) async {
    return await _repository.login(params.email, params.password);
  }
}

class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
