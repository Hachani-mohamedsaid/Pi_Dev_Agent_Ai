import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase implements AsyncUseCase<void, ResetPasswordParams> {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(ResetPasswordParams params) async {
    return await _repository.resetPassword(params.email);
  }
}

class ResetPasswordParams {
  const ResetPasswordParams({required this.email});

  final String email;
}
