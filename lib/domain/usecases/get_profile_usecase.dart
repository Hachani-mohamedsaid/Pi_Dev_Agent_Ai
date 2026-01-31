import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class GetProfileUseCase implements AsyncUseCase<dynamic, NoParams> {
  const GetProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<dynamic> call(NoParams params) async {
    return _repository.getProfile();
  }
}
