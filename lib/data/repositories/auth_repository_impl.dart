import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

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
    final userModel = await _remoteDataSource.login(email, password);
    await _localDataSource.cacheUser(userModel);
    return userModel;
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final userModel = await _remoteDataSource.register(name, email, password);
    await _localDataSource.cacheUser(userModel);
    return userModel;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
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
  Future<User> loginWithGoogle() async {
    final userModel = await _remoteDataSource.loginWithGoogle();
    await _localDataSource.cacheUser(userModel);
    return userModel;
  }

  @override
  Future<User> loginWithApple() async {
    final userModel = await _remoteDataSource.loginWithApple();
    await _localDataSource.cacheUser(userModel);
    return userModel;
  }
}
