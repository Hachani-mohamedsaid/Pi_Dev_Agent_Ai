# Document de consommation API – Flutter

Référence pour connecter l'application Flutter au backend NestJS : auth, profil dynamique, reset password.

---

## 1. Configuration

### Base URL

```dart
// Développement
const String baseUrl = 'http://localhost:3000';

// Émulateur Android : utiliser 10.0.2.2 au lieu de localhost
// const String baseUrl = 'http://10.0.2.2:3000';

// Production (ex. Railway)
const String baseUrl = 'https://ton-backend.up.railway.app';
```

### Headers

- **Content-Type** : `application/json` pour les requêtes avec body.
- **Authorization** : `Bearer <accessToken>` pour les routes protégées (`GET /auth/me`, `PATCH /auth/me`).

---

## 2. Modèles Dart

### UserModel (réponse login/register)

```dart
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({...});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
```

### ProfileModel (réponse GET /auth/me – profil dynamique)

Voir `lib/data/models/profile_model.dart`. Getter `joinedLabel` pour "Joined January 2024".

### AuthResponse (login, register, Google, Apple)

`user` (UserModel) + `accessToken` — voir `lib/data/models/auth_response.dart`.

---

## 3. Endpoints et exemples Dart

### 3.1 Inscription – POST /auth/register

Body: `{ "name", "email", "password" }`. Succès 201 → `AuthResponse`. Erreur 409 = email déjà utilisé.

### 3.2 Connexion – POST /auth/login ou /auth/signin

Body: `{ "email", "password" }`. Succès 200 → `AuthResponse`. Erreur 401 = identifiants incorrects.

### 3.3 Demande reset MDP – POST /auth/reset-password

Body: `{ "email" }`. Succès 200 → `{ "message" }`.

### 3.4 Nouveau MDP (lien email) – POST /auth/reset-password/confirm

Body: `{ "token", "newPassword" }`. Succès 200. Erreur 400 = token invalide ou expiré.

### 3.5 Connexion Google – POST /auth/google

Body: `{ "idToken" }`. Succès 200 → `AuthResponse`.

### 3.6 Connexion Apple – POST /auth/apple

Body: `{ "identityToken", "user"?: "string" }`. Succès 200 → `AuthResponse`.

### 3.7 Profil (données dynamiques) – GET /auth/me

Header: `Authorization: Bearer <accessToken>`. Succès 200 → `ProfileModel`.

### 3.8 Mise à jour profil – PATCH /auth/me

Body optionnels: `name?`, `role?`, `location?`, `conversationsCount?`, `hoursSaved?`. Succès 200.

### 3.9 Santé backend – GET /health

Succès 200 → `{ "status": "ok", "mongodb": "connected" }`.

---

## 4. Gestion des erreurs

`{ "statusCode": number, "message": string | string[], "error"?: string }`. Codes : 200/201 succès, 400 validation, 401 non autorisé, 409 conflit.

---

## 5. Stockage du token

Après register/login/google/apple : récupérer `accessToken` depuis `AuthResponse`, le stocker (shared_preferences ou flutter_secure_storage), envoyer `Authorization: Bearer <accessToken>` sur les routes protégées.

---

## 6. Flux page Profile

1. Au login, stocker `accessToken`.
2. Sur l’écran Profile, appeler **GET /auth/me** avec le token.
3. Mapper en **ProfileModel** et afficher : nom, email, rôle, localisation, "Joined …", et les 3 stats.
4. Pour l’édition : **PATCH /auth/me**, puis recharger le profil.

---

## 7. Récapitulatif des routes

| Action Flutter       | Méthode | Route                           | Body / Header                    |
|----------------------|--------|----------------------------------|----------------------------------|
| Inscription          | POST   | `/auth/register`                | name, email, password            |
| Connexion            | POST   | `/auth/login` ou `/auth/signin` | email, password                  |
| Demande reset MDP    | POST   | `/auth/reset-password`          | email                            |
| Nouveau MDP (lien)   | POST   | `/auth/reset-password/confirm`  | token, newPassword               |
| Connexion Google     | POST   | `/auth/google`                  | idToken                          |
| Connexion Apple      | POST   | `/auth/apple`                   | identityToken, user?             |
| Profil (dynamique)   | GET    | `/auth/me`                      | Header: Bearer token             |
| Mise à jour profil   | PATCH  | `/auth/me`                      | name?, role?, location?, …       |
| Santé backend        | GET    | `/health`                       | —                                |

---

## 8. Dépendances Dart

```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.2
```

---

## 9. CORS et environnements

- Backend : CORS activé en dev.
- Émulateur Android : `http://10.0.2.2:3000` au lieu de localhost.
- iOS Simulator : `http://localhost:3000`.
- App physique : IP de la machine ou URL Railway en production.
