import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> resetPassword(String email);
  Future<User?> getCurrentUser();
  Future<void> logout();

  /// idToken fourni par Google Sign-In.
  Future<User> loginWithGoogle(String idToken);

  /// identityToken + user optionnel fournis par Sign in with Apple.
  Future<User> loginWithApple(String identityToken, {String? user});

  /// POST /auth/reset-password/confirm – nouveau MDP avec token du lien email.
  Future<void> setNewPassword({
    required String token,
    required String newPassword,
  });

  /// POST /auth/change-password – changer le MDP (utilisateur connecté).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// GET /auth/me – profil avec stats (role, location, etc.).
  Future<dynamic> getProfile();

  /// PATCH /auth/me – mise à jour du profil.
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
  });

  /// POST /auth/verify-email – envoi email avec lien (Resend). Utilisateur connecté (Bearer).
  Future<void> requestEmailVerification();

  /// POST /auth/verify-email/confirm – confirmation avec token du lien email.
  Future<void> confirmEmailVerification(String token);
}
