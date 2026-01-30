# Document de consommation API – Flutter

Document de référence pour connecter l'application Flutter au backend NestJS (auth, reset password, etc.).

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

### Headers communs

- **Content-Type** : `application/json` pour les requêtes avec body.
- **Authorization** : `Bearer <accessToken>` pour les routes protégées (ex. `GET /auth/me`).

---

## 2. Modèles

### UserModel

Le backend renvoie un utilisateur avec **id**, **name**, **email** uniquement.

```dart
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };
}
```

### AuthResponse

Réponse des routes : register, login, google, apple.

```dart
class AuthResponse {
  final UserModel user;
  final String accessToken;

  AuthResponse({ required this.user, required this.accessToken });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(
        Map<String, dynamic>.from(json['user'] ?? {}),
      ),
      accessToken: json['accessToken'] as String? ?? '',
    );
  }
}
```

---

## 3. Endpoints et exemples Dart

### 3.1 Inscription – POST /auth/register

| Élément   | Valeur |
|----------|--------|
| Méthode  | POST   |
| URL      | `$baseUrl/auth/register` |
| Body     | `{ "name": "string", "email": "string", "password": "string" }` |
| Succès   | 201 → `AuthResponse` |
| Erreur   | 409 = email déjà utilisé ; 400 = validation |

### 3.2 Connexion – POST /auth/login ou /auth/signin

| Élément   | Valeur |
|----------|--------|
| Méthode  | POST   |
| URL      | `$baseUrl/auth/login` ou `$baseUrl/auth/signin` |
| Body     | `{ "email": "string", "password": "string" }` |
| Succès   | 200 → `AuthResponse` |
| Erreur   | 401 = identifiants incorrects |

### 3.3 Demande de réinitialisation – POST /auth/reset-password

| Élément   | Valeur |
|----------|--------|
| Méthode  | POST   |
| URL      | `$baseUrl/auth/reset-password` |
| Body     | `{ "email": "string" }` |
| Succès   | 200 → `{ "message": "string" }` |

Le backend envoie un email (SendGrid) avec un lien du type :  
`{RESET_LINK_BASE_URL}?token=xxx` (token valide 1h).

### 3.4 Définir le nouveau mot de passe – POST /auth/reset-password/confirm

À appeler quand l'utilisateur a cliqué sur le lien reçu par email (récupérer `token` depuis l'URL : `?token=xxx`).

| Élément   | Valeur |
|----------|--------|
| Méthode  | POST   |
| URL      | `$baseUrl/auth/reset-password/confirm` |
| Body     | `{ "token": "string", "newPassword": "string" }` |
| Succès   | 200 → `{ "message": "string" }` |
| Erreur   | 400 = token invalide ou expiré |

### 3.5 Connexion Google – POST /auth/google

| Élément   | Valeur |
|----------|--------|
| Méthode  | POST   |
| URL      | `$baseUrl/auth/google` |
| Body     | `{ "idToken": "string" }` (token Google côté client) |
| Succès   | 200 → `AuthResponse` |

### 3.6 Connexion Apple – POST /auth/apple

| Élément   | Valeur |
|----------|--------|
| Méthode  | POST   |
| URL      | `$baseUrl/auth/apple` |
| Body     | `{ "identityToken": "string", "user"?: "string" }` |
| Succès   | 200 → `AuthResponse` |

### 3.7 Utilisateur connecté – GET /auth/me

| Élément   | Valeur |
|----------|--------|
| Méthode  | GET    |
| URL      | `$baseUrl/auth/me` |
| Header   | `Authorization: Bearer <accessToken>` |
| Succès   | 200 → `{ "id", "name", "email" }` |
| Erreur   | 401 = non connecté ou token expiré |

### 3.8 Santé backend – GET /health

| Élément   | Valeur |
|----------|--------|
| Méthode  | GET    |
| URL      | `$baseUrl/health` |
| Succès   | 200 → `{ "status": "ok", "mongodb": "connected" }` |

---

## 4. Gestion des erreurs

Réponses d'erreur du backend :  
`{ "statusCode": number, "message": string | string[], "error"?: string }`.

Codes courants : **400** = validation, **401** = non autorisé, **409** = conflit (ex. email déjà utilisé).

---

## 5. Stockage du token

Après un **register**, **login**, **google** ou **apple** réussi : stocker **accessToken** (shared_preferences ou flutter_secure_storage). Pour les requêtes protégées : **Authorization: Bearer &lt;accessToken&gt;**.

---

## 6. Parcours Reset Password (Flutter)

1. **Page "Reset Password"** (email uniquement) → POST /auth/reset-password.
2. **Lien reçu par email** → ouvrir page "Nouveau mot de passe" avec `?token=xxx`.
3. **Page "Nouveau mot de passe"** → POST /auth/reset-password/confirm avec token + newPassword → succès → redirection Sign In.

---

## 7. Récapitulatif des routes

| Action Flutter        | Méthode | Route                          | Body / Header                    |
|-----------------------|--------|--------------------------------|----------------------------------|
| Inscription           | POST   | `/auth/register`               | name, email, password            |
| Connexion             | POST   | `/auth/login` ou `/auth/signin`| email, password                  |
| Demande reset MDP     | POST   | `/auth/reset-password`         | email                            |
| Nouveau MDP (lien)    | POST   | `/auth/reset-password/confirm`  | token, newPassword               |
| Connexion Google      | POST   | `/auth/google`                 | idToken                          |
| Connexion Apple       | POST   | `/auth/apple`                  | identityToken, user?             |
| Profil (connecté)      | GET    | `/auth/me`                     | Header: `Authorization: Bearer <token>` |
| Santé backend         | GET    | `/health`                      | —                                |

---

## 8. Dépendances Dart suggérées

```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.2
```

Ce document peut être utilisé tel quel par l'équipe Flutter pour implémenter la consommation de l'API backend.
