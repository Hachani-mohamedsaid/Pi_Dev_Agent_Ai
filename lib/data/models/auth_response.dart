import 'user_model.dart';

/// Réponse des routes auth (register, login, google, apple).
/// Contient l'utilisateur et le JWT à stocker et envoyer en header.
class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.accessToken,
  });

  final UserModel user;
  final String accessToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final userMap = userJson is Map<String, dynamic>
        ? userJson
        : Map<String, dynamic>.from(userJson as Map? ?? {});
    return AuthResponse(
      user: UserModel.fromJson(userMap),
      accessToken: json['accessToken'] as String? ?? '',
    );
  }
}
