import '../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements AsyncUseCase<User?, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<User?> call(NoParams params) async {
    return await _repository.getCurrentUser();
  }
}
