import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> resetPassword(String email);
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<User> loginWithGoogle();
  Future<User> loginWithApple();
}
