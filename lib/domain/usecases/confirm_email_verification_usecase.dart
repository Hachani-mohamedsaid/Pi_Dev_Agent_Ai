import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ConfirmEmailVerificationUseCase
    implements AsyncUseCase<void, ConfirmEmailVerificationParams> {
  const ConfirmEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(ConfirmEmailVerificationParams params) async {
    return await _repository.confirmEmailVerification(params.token);
  }
}

class ConfirmEmailVerificationParams {
  const ConfirmEmailVerificationParams({required this.token});

  final String token;
}
