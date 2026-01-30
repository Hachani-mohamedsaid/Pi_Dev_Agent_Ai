# Documentation de consommation API – Code Flutter

Document de référence pour consommer l’API backend NestJS depuis une application Flutter : authentification, profil dynamique, reset password, **changement de mot de passe**.

**Backend** : NestJS + MongoDB  
**Base URL** : `https://ton-backend.up.railway.app` ou `http://localhost:3000`

---

## Sommaire

| Section | Contenu |
|--------|--------|
| **1. Configuration** | Base URL (dev / prod), headers |
| **2. Modèles Dart** | `UserModel`, `ProfileModel`, `AuthResponse` – voir `lib/data/models/` |
| **3. Endpoints** | Inscription, connexion, reset password, Google, Apple, **GET /auth/me**, **PATCH /auth/me**, **POST /auth/change-password**, health |
| **4. Gestion des erreurs** | `_parseError`, codes 400 / 401 / 409 |
| **5. Stockage du token** | SharedPreferences (ou secure storage) après login |
| **6. Flux Profile et Edit Profile** | Chargement du profil, pré-remplissage, sauvegarde (dont téléphone) |
| **7. Récapitulatif des routes** | Tableau de toutes les routes (méthode, URL, body / header) |
| **8. Dépendances et environnements** | `http`, `shared_preferences`, URLs selon l’environnement |
| **9. Page Change Password** | Formulaire dynamique : validation en temps réel + appel **POST /auth/change-password** |
| **10. Photo de profil (ImgBB)** | Tap to change photo → image_picker → upload ImgBB → PATCH /auth/me avec avatarUrl |

---

## 1. Configuration

### Base URL

- **Développement** : `http://localhost:3000`
- **Émulateur Android** : `http://10.0.2.2:3000`
- **Production** : `https://ton-backend.up.railway.app`

### Headers

| Header | Usage |
|--------|--------|
| `Content-Type: application/json` | Requêtes avec body (POST, PATCH) |
| `Authorization: Bearer <accessToken>` | Routes protégées : GET /auth/me, PATCH /auth/me, **POST /auth/change-password** |

---

## 2. Modèles Dart

- **UserModel** : `lib/data/models/user_model.dart` – id, name, email (réponse login/register/Google/Apple).
- **ProfileModel** : `lib/data/models/profile_model.dart` – id, name, email, **avatarUrl**, role, location, phone, birthDate, bio, createdAt, conversationsCount, daysActive, hoursSaved, getter `joinedLabel`.
- **AuthResponse** : `lib/data/models/auth_response.dart` – user (UserModel) + accessToken.

---

## 3. Endpoints

- **POST /auth/register** : body `name`, `email`, `password` → 201 AuthResponse
- **POST /auth/login** ou **/auth/signin** : body `email`, `password` → 200 AuthResponse
- **POST /auth/reset-password** : body `email` → 200
- **POST /auth/reset-password/confirm** : body `token`, `newPassword` → 200
- **POST /auth/google** : body `idToken` → 200 AuthResponse
- **POST /auth/apple** : body `identityToken`, `user?` → 200 AuthResponse
- **GET /auth/me** : header `Authorization: Bearer <token>` → 200 ProfileModel
- **PATCH /auth/me** : header + body optionnels (name, **avatarUrl**, role, location, phone, birthDate, bio, …) → 200
- **POST /auth/change-password** : header `Authorization: Bearer <token>` + body `currentPassword`, `newPassword` → 200
- **GET /health** : 200 → `{ "status": "ok" }`

---

## 4. Gestion des erreurs

Réponses d’erreur : `{ "statusCode": number, "message": string | string[], "error"?: string }`.  
Codes : 200/201 succès, 400 validation, 401 non autorisé, 409 conflit.

---

## 5. Stockage du token

Après register/login/google/apple : récupérer `accessToken`, le stocker (SharedPreferences ou flutter_secure_storage), envoyer `Authorization: Bearer <accessToken>` sur toutes les routes protégées (GET /auth/me, PATCH /auth/me, POST /auth/change-password).

---

## 6. Flux Profile et Edit Profile

- **Page Profile** : au chargement, GET /auth/me avec le token → afficher ProfileModel (name, email, role, location, phone, birthDate, bio, joinedLabel, stats).
- **Page Edit Profile** : pré-remplir les champs depuis le ProfileModel ; au **Save Changes**, PATCH /auth/me avec les champs modifiés.

---

## 7. Récapitulatif des routes

| Action | Méthode | Route |
|--------|--------|-------|
| Inscription | POST | `/auth/register` |
| Connexion | POST | `/auth/login` ou `/auth/signin` |
| Profil (données dynamiques) | GET | `/auth/me` (Header: Bearer token) |
| Mise à jour profil | PATCH | `/auth/me` |
| **Changer le mot de passe** | POST | **`/auth/change-password`** (Header: Bearer token, body: currentPassword, newPassword) |
| Reset password (demande) | POST | `/auth/reset-password` |
| Nouveau MDP (lien email) | POST | `/auth/reset-password/confirm` |
| Connexion Google | POST | `/auth/google` |
| Connexion Apple | POST | `/auth/apple` |
| Santé backend | GET | `/health` |

---

## 8. Dépendances et environnements

```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.2
  image_picker: ^1.0.7   # Photo de profil (section 10)
```

| Contexte | Base URL |
|----------|----------|
| Dev (machine) | `http://localhost:3000` |
| Émulateur Android | `http://10.0.2.2:3000` |
| iOS Simulator | `http://localhost:3000` |
| Production | `https://ton-backend.up.railway.app` |

---

## 9. Page Change Password

- **Route** : `/change-password` (depuis Paramètres / Privacy & Security).
- **Formulaire** : mot de passe actuel, nouveau mot de passe, confirmation du nouveau mot de passe.
- **Validation en temps réel** : force du mot de passe (longueur, majuscule/minuscule, chiffre, caractère spécial), correspondance des deux champs « nouveau mot de passe ».
- **Soumission** : appel **POST /auth/change-password** avec header `Authorization: Bearer <accessToken>` et body `{ "currentPassword", "newPassword" }`. En cas de succès (200), afficher un message de succès et revenir en arrière ; en cas d’erreur (ex. 401, mot de passe actuel incorrect), afficher le message d’erreur du backend.

Implémentation dans le projet : `lib/presentation/pages/change_password_page.dart` (branchée sur `AuthController.changePassword()` qui appelle l’API).

---

## 10. Photo de profil (ImgBB)

- **Flux** : sur la page Edit Profile, « Tap to change photo » ouvre la galerie (image_picker) → l’utilisateur choisit une image → l’image est envoyée à **ImgBB** (POST https://api.imgbb.com/1/upload avec `key` + `image` en base64) → l’URL retournée est envoyée au backend via **PATCH /auth/me** avec `avatarUrl`.
- **Backend** : le schéma utilisateur doit accepter un champ `avatarUrl` (string) ; GET /auth/me retourne `avatarUrl`, PATCH /auth/me accepte `avatarUrl` dans le body.
- **Flutter** :
  - Dépendance : `image_picker: ^1.0.7`.
  - Config : `lib/core/config/imgbb_config.dart` – clé API ImgBB (obtenir une clé gratuite sur https://api.imgbb.com/). Si la clé est vide, l’upload affiche un message invitant à la configurer.
  - Service : `lib/data/services/imgbb_upload_service.dart` – `ImgBBUploadService.uploadImage(bytes)` retourne l’URL de l’image ou null.
  - Page Edit Profile : au tap sur la zone photo, `ImagePicker().pickImage(source: ImageSource.gallery)` → `readAsBytes()` → `ImgBBUploadService.uploadImage(bytes)` → `AuthController.updateProfile(avatarUrl: url)` → rechargement du profil.
  - Page Profile et Edit Profile : si `profile.avatarUrl` est renseigné, afficher `Image.network(profile.avatarUrl)` ; sinon afficher les initiales.

---

*Documentation de consommation API pour le code Flutter – Backend NestJS. Sections 1 à 10.*
