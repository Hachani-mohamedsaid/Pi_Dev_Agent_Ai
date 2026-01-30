import '../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements AsyncUseCase<User, RegisterParams> {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<User> call(RegisterParams params) async {
    return await _repository.register(
      params.name,
      params.email,
      params.password,
    );
  }
}

class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}
