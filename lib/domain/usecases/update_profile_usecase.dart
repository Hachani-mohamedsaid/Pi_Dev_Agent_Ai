import '../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase implements AsyncUseCase<void, UpdateProfileParams> {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(UpdateProfileParams params) async {
    return _repository.updateProfile(
      name: params.name,
      avatarUrl: params.avatarUrl,
      role: params.role,
      location: params.location,
      phone: params.phone,
      birthDate: params.birthDate,
      bio: params.bio,
      conversationsCount: params.conversationsCount,
      hoursSaved: params.hoursSaved,
    );
  }
}

class UpdateProfileParams {
  const UpdateProfileParams({
    this.name,
    this.avatarUrl,
    this.role,
    this.location,
    this.phone,
    this.birthDate,
    this.bio,
    this.conversationsCount,
    this.hoursSaved,
  });

  final String? name;
  final String? avatarUrl;
  final String? role;
  final String? location;
  final String? phone;
  final String? birthDate;
  final String? bio;
  final int? conversationsCount;
  final int? hoursSaved;
}
