import '../entities/user.dart';
import '../../core/error/failure.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> resetPassword(String email);
<<<<<<< HEAD
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<User> loginWithGoogle();
  Future<User> loginWithApple();
=======
  Future<void> confirmResetPassword(String token, String newPassword);
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<User> loginWithGoogle(String idToken);
  Future<User> loginWithApple(String identityToken, {String? user});
>>>>>>> c3cf2c9 ( Flutter project v1)
}
