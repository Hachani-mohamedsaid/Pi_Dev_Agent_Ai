# Documentation de consommation API – Code Flutter

Document de référence pour consommer l’API backend NestJS depuis une application Flutter : authentification, profil dynamique (nom, email, téléphone, localisation, date de naissance, bio), reset password.

**Backend** : NestJS + MongoDB  
**Base URL** : `https://ton-backend.up.railway.app` ou `http://localhost:3000`

---

## Sommaire

1. [Configuration](#1-configuration)
2. [Modèles Dart](#2-modèles-dart)
3. [Endpoints et exemples de code](#3-endpoints-et-exemples-de-code)
4. [Gestion des erreurs](#4-gestion-des-erreurs)
5. [Stockage du token](#5-stockage-du-token)
6. [Flux Profile et Edit Profile](#6-flux-profile-et-edit-profile)
7. [Récapitulatif des routes](#7-récapitulatif-des-routes)
8. [Dépendances et environnements](#8-dépendances-et-environnements)

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

| Header | Usage |
|--------|--------|
| `Content-Type: application/json` | Requêtes avec body (POST, PATCH) |
| `Authorization: Bearer <accessToken>` | Routes protégées : GET /auth/me, PATCH /auth/me |

---

## 2. Modèles Dart

### UserModel (réponse login / register / Google / Apple)

Voir `lib/data/models/user_model.dart` : `id`, `name`, `email` (avec `_id` MongoDB).

### ProfileModel (réponse GET /auth/me – page Profile et Edit Profile)

Voir `lib/data/models/profile_model.dart` : `id`, `name`, `email`, `role`, `location`, `phone`, `birthDate`, `bio`, `createdAt`, `conversationsCount`, `daysActive`, `hoursSaved`. Getter `joinedLabel` pour "Joined January 2024".

### AuthResponse (register, login, Google, Apple)

Voir `lib/data/models/auth_response.dart` : `user` (UserModel) + `accessToken`.

---

## 3. Endpoints et exemples de code

- **POST /auth/register** : body `name`, `email`, `password` → 201 AuthResponse
- **POST /auth/login** ou **/auth/signin** : body `email`, `password` → 200 AuthResponse
- **POST /auth/reset-password** : body `email` → 200
- **POST /auth/reset-password/confirm** : body `token`, `newPassword` → 200
- **POST /auth/google** : body `idToken` → 200 AuthResponse
- **POST /auth/apple** : body `identityToken`, `user?` → 200 AuthResponse
- **GET /auth/me** : header `Authorization: Bearer <token>` → 200 ProfileModel (name, email, role, location, phone, birthDate, bio, createdAt, stats)
- **PATCH /auth/me** : header + body optionnels `name`, `role`, `location`, `phone`, `birthDate`, `bio`, `conversationsCount`, `hoursSaved` → 200
- **GET /health** : 200 → `{ "status": "ok" }`

---

## 4. Gestion des erreurs

`{ "statusCode": number, "message": string | string[], "error"?: string }`. Codes : 200/201 succès, 400 validation, 401 non autorisé, 409 conflit.

---

## 5. Stockage du token

Après register/login/google/apple : récupérer `accessToken`, le stocker (SharedPreferences ou flutter_secure_storage), envoyer `Authorization: Bearer <accessToken>` sur GET /auth/me et PATCH /auth/me.

---

## 6. Flux Profile et Edit Profile

### Page Profile

Au chargement : GET /auth/me avec le token → mapper en ProfileModel → afficher name, email, role, location, phone, birthDate, bio, joinedLabel, stats.

### Page Edit Profile

À l’ouverture : pré-remplir Full Name, Email, Phone Number, Location, Birth Date, Bio / Rôle depuis le ProfileModel (ou GET /auth/me). Au **Save Changes** : PATCH /auth/me avec les champs modifiés (name, role, location, phone, birthDate, bio).

---

## 7. Récapitulatif des routes

| Action | Méthode | Route | Body / Header |
|--------|--------|-------|----------------|
| Inscription | POST | `/auth/register` | name, email, password |
| Connexion | POST | `/auth/login` ou `/auth/signin` | email, password |
| Demande reset MDP | POST | `/auth/reset-password` | email |
| Nouveau MDP (lien) | POST | `/auth/reset-password/confirm` | token, newPassword |
| Connexion Google | POST | `/auth/google` | idToken |
| Connexion Apple | POST | `/auth/apple` | identityToken, user? |
| Profil (données dynamiques) | GET | `/auth/me` | Header: Bearer token |
| Mise à jour profil | PATCH | `/auth/me` | name?, role?, location?, phone?, birthDate?, bio?, conversationsCount?, hoursSaved? |
| Santé backend | GET | `/health` | — |

---

## 8. Dépendances et environnements

```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.2
```

| Contexte | Base URL |
|----------|----------|
| Dev (machine) | `http://localhost:3000` |
| Émulateur Android | `http://10.0.2.2:3000` |
| iOS Simulator | `http://localhost:3000` |
| Production | `https://ton-backend.up.railway.app` |

---

*Documentation de consommation API pour le code Flutter – Backend NestJS.*
