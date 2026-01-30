import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase implements AsyncUseCase<void, ChangePasswordParams> {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(ChangePasswordParams params) async {
    return _repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class ChangePasswordParams {
  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}
