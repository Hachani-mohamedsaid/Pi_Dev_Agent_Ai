import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordConfirmUseCase
    implements AsyncUseCase<void, ResetPasswordConfirmParams> {
  const ResetPasswordConfirmUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(ResetPasswordConfirmParams params) async {
    return await _repository.setNewPassword(
      token: params.token,
      newPassword: params.newPassword,
    );
  }
}

class ResetPasswordConfirmParams {
  const ResetPasswordConfirmParams({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;
}
