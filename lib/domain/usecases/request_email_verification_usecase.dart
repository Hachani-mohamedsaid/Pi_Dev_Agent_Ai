import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class RequestEmailVerificationUseCase implements AsyncUseCase<void, NoParams> {
  const RequestEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(NoParams params) async {
    return await _repository.requestEmailVerification();
  }
}
