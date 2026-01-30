import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ConfirmResetPasswordUseCase
    implements AsyncUseCase<void, ConfirmResetPasswordParams> {
  const ConfirmResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(ConfirmResetPasswordParams params) async {
    return await _repository.confirmResetPassword(
      params.token,
      params.newPassword,
    );
  }
}

class ConfirmResetPasswordParams {
  const ConfirmResetPasswordParams({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;
}
