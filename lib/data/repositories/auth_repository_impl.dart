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

<<<<<<< HEAD
  @override
  Future<User> login(String email, String password) async {
    final userModel = await _remoteDataSource.login(email, password);
    await _localDataSource.cacheUser(userModel);
    return userModel;
=======
  Future<void> _saveAuthResponse(UserModel user, String accessToken) async {
    await _localDataSource.saveAccessToken(accessToken);
    await _localDataSource.cacheUser(user);
  }

  @override
  Future<User> login(String email, String password) async {
    final auth = await _remoteDataSource.login(email, password);
    await _saveAuthResponse(auth.user, auth.accessToken);
    return auth.user;
>>>>>>> c3cf2c9 ( Flutter project v1)
  }

  @override
  Future<User> register(String name, String email, String password) async {
<<<<<<< HEAD
    final userModel = await _remoteDataSource.register(name, email, password);
    await _localDataSource.cacheUser(userModel);
    return userModel;
=======
    final auth = await _remoteDataSource.register(name, email, password);
    await _saveAuthResponse(auth.user, auth.accessToken);
    return auth.user;
>>>>>>> c3cf2c9 ( Flutter project v1)
  }

  @override
  Future<void> resetPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
  }

  @override
<<<<<<< HEAD
  Future<User?> getCurrentUser() async {
    final userModel = await _localDataSource.getCachedUser();
    return userModel;
=======
  Future<void> confirmResetPassword(String token, String newPassword) async {
    await _remoteDataSource.confirmResetPassword(token, newPassword);
  }

  @override
  Future<User?> getCurrentUser() async {
    UserModel? user = await _localDataSource.getCachedUser();
    final token = await _localDataSource.getAccessToken();
    if (user == null && token != null && token.isNotEmpty) {
      try {
        user = await _remoteDataSource.getMe(token);
        await _localDataSource.cacheUser(user);
      } catch (_) {
        await _localDataSource.clearCache();
      }
    }
    return user;
>>>>>>> c3cf2c9 ( Flutter project v1)
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearCache();
  }

  @override
<<<<<<< HEAD
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
=======
  Future<User> loginWithGoogle(String idToken) async {
    final auth = await _remoteDataSource.loginWithGoogle(idToken);
    await _saveAuthResponse(auth.user, auth.accessToken);
    return auth.user;
  }

  @override
  Future<User> loginWithApple(String identityToken, {String? user}) async {
    final auth = await _remoteDataSource.loginWithApple(
      identityToken,
      user: user,
    );
    await _saveAuthResponse(auth.user, auth.accessToken);
    return auth.user;
>>>>>>> c3cf2c9 ( Flutter project v1)
  }
}
