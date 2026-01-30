import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<User> login(String email, String password) async {
    final res = await _remoteDataSource.login(email, password);
    await _localDataSource.cacheUser(res.user);
    if (res.accessToken.isNotEmpty) {
      await _localDataSource.saveAccessToken(res.accessToken);
    }
    return res.user;
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final res = await _remoteDataSource.register(name, email, password);
    await _localDataSource.cacheUser(res.user);
    if (res.accessToken.isNotEmpty) {
      await _localDataSource.saveAccessToken(res.accessToken);
    }
    return res.user;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
  }

  @override
  Future<void> setNewPassword({required String token, required String newPassword}) async {
    await _remoteDataSource.setNewPassword(token: token, newPassword: newPassword);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    await _remoteDataSource.changePassword(
      token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await _localDataSource.getCachedUser();
    return userModel;
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearCache();
  }

  @override
  Future<User> loginWithGoogle(String idToken) async {
    final res = await _remoteDataSource.loginWithGoogle(idToken);
    await _localDataSource.cacheUser(res.user);
    if (res.accessToken.isNotEmpty) {
      await _localDataSource.saveAccessToken(res.accessToken);
    }
    return res.user;
  }

  @override
  Future<User> loginWithApple(String identityToken, {String? user}) async {
    final res = await _remoteDataSource.loginWithApple(identityToken, user: user);
    await _localDataSource.cacheUser(res.user);
    if (res.accessToken.isNotEmpty) {
      await _localDataSource.saveAccessToken(res.accessToken);
    }
    return res.user;
  }

  @override
  Future<ProfileModel> getProfile() async {
    final token = await _localDataSource.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return _remoteDataSource.getProfile(token);
    }
    final user = await _localDataSource.getCachedUser();
    if (user == null) {
      throw Exception('Not authenticated');
    }
    return ProfileModel(
      id: user.id,
      name: user.name,
      email: user.email,
    );
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? role,
    String? location,
    String? phone,
    String? birthDate,
    String? bio,
    int? conversationsCount,
    int? hoursSaved,
  }) async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) return;
    await _remoteDataSource.updateProfile(
      token,
      name: name,
      avatarUrl: avatarUrl,
      role: role,
      location: location,
      phone: phone,
      birthDate: birthDate,
      bio: bio,
      conversationsCount: conversationsCount,
      hoursSaved: hoursSaved,
    );
  }
}
