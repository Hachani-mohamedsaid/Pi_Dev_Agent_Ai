# Prompt Backend NestJS + MongoDB — App AI Assistant

## Contexte

Une application Flutter (client mobile) possède déjà une page **Create Account** avec :
- Champs : **Full Name**, **Email**, **Password**, **Confirm Password**
- Bouton **Sign Up**
- Connexion sociale : **Google Account**, **Apple Account**
- Lien **Sign In** (déjà inscrits)

Le client appelle actuellement un `MockAuthRemoteDataSource`. Il faut créer un **backend NestJS + MongoDB** qui implémente les vrais endpoints d’authentification et s’aligne sur ces appels.

---

## Contrat API côté Flutter (à respecter)

| Méthode Flutter | Rôle | Paramètres | Réponse attendue |
|-----------------|------|------------|-------------------|
| `register(name, email, password)` | Inscription | name, email, password | `UserModel` (id, name, email) |
| `login(email, password)` | Connexion | email, password | `UserModel` (id, name, email) |
| `resetPassword(email)` | Demande reset MDP (envoi email) | email | void / succès |
| `confirmResetPassword(token, newPassword)` | Définir nouveau MDP (après clic lien email) | token, newPassword | void / succès |
| `loginWithGoogle()` | Connexion Google | — | `UserModel` (id, name, email) |
| `loginWithApple()` | Connexion Apple | — | `UserModel` (id, name, email) |

**Format User côté client :**
```json
{
  "id": "string",
  "name": "string",
  "email": "string"
}
```

Après login/register réussi, le client s’attend à recevoir un **token JWT** (dans un header ou un champ `accessToken` / `token`) pour les requêtes authentifiées.

---

## Objectifs du projet NestJS + MongoDB

Créer une API REST qui :

1. **Inscription** : `POST /auth/register` (ou `/auth/signup`) avec `name`, `email`, `password`.
2. **Connexion** : `POST /auth/login` (ou `/auth/signin`) avec `email`, `password`.
3. **Demande réinitialisation mot de passe** : `POST /auth/reset-password` avec `email` (envoi d’un email avec lien contenant un token, ex. validité 1h).
4. **Confirmation nouveau mot de passe** : `POST /auth/reset-password/confirm` avec `token` (du lien email) et `newPassword`. À appeler quand l’utilisateur a cliqué sur le lien reçu par email. Succès 200 ; 400 si token invalide ou expiré.
5. **Connexion Google** : `POST /auth/google` (body avec `idToken` ou `accessToken` Google).
6. **Connexion Apple** : `POST /auth/apple` (body avec `identityToken` + `user` si fourni par le client).
7. **Santé backend** (optionnel) : `GET /health` → 200 avec `{ "status": "ok", "mongodb": "connected" }` pour vérifier que l’API et la base sont disponibles.

Réponses : renvoyer un objet **user** (id, name, email) + **accessToken** (JWT) pour que le Flutter puisse stocker le token et l’envoyer en header `Authorization: Bearer <token>`.

---

## Spécifications techniques

### 1. Modèle User (MongoDB / Mongoose)

- **fullName** (String, required) — ou `name` pour coller au Flutter.
- **email** (String, required, unique, index).
- **password** (String, required) — **toujours stocké hashé** (bcrypt), jamais en clair.
- **googleId** (String, optional) — pour compte lié Google.
- **appleId** (String, optional) — pour compte lié Apple.
- **createdAt**, **updatedAt** (timestamps).

Exposer vers le client uniquement : `id`, `name` (ou fullName), `email` (pas de `password`, `googleId`, `appleId` dans la réponse).

### 2. Module Auth (NestJS)

- **AuthModule** avec :
  - **AuthController** : routes `POST /auth/register`, `POST /auth/login`, `POST /auth/reset-password`, `POST /auth/reset-password/confirm`, `POST /auth/google`, `POST /auth/apple`, et optionnellement `GET /health`.
  - **AuthService** : logique métier (validation, hash, vérification, création/utilisateur, génération JWT).
  - **JWT** : utiliser `@nestjs/jwt` + `@nestjs/passport` (strategy JWT) pour protéger les routes qui nécessitent un utilisateur connecté.
- **UsersModule** (ou User intégré dans Auth) :
  - **User**, **UserSchema** (Mongoose).
  - **UsersService** (création, findByEmail, findByGoogleId, findByAppleId, etc.).

### 3. DTOs et validation

- **RegisterDto** : `name`, `email`, `password` (avec `class-validator`).
  - email : format email valide.
  - password : longueur minimale (ex. 8 caractères), à définir selon la politique.
- **LoginDto** : `email`, `password`.
- **ResetPasswordDto** : `email`.
- **ConfirmResetPasswordDto** : `token` (string, le token du lien email), `newPassword` (string, règles de validation identiques au mot de passe d’inscription).
- **GoogleAuthDto** : `idToken` ou `accessToken` (selon ce que le Flutter envoie).
- **AppleAuthDto** : `identityToken`, optionnellement `user` (name, email) si fourni par le client.

Utiliser **ValidationPipe** global pour rejeter les requêtes invalides avec messages clairs.

### 4. Sécurité

- Hash des mots de passe avec **bcrypt** (ou `argon2`).
- **JWT** : secret en variable d’environnement, expiration raisonnable (ex. 7j ou 15j).
- Ne jamais renvoyer le mot de passe (même hashé) dans les réponses.
- Gérer les erreurs sans exposer de détails internes (ex. “Email ou mot de passe incorrect” pour login au lieu de “User not found”).

### 5. Gestion des erreurs

- **409 Conflict** : email déjà utilisé à l’inscription.
- **401 Unauthorized** : identifiants incorrects à la connexion.
- **400 Bad Request** : validation DTO échouée.
- **404** : optionnel pour “email non trouvé” en reset password (selon politique : souvent on renvoie toujours 200 pour ne pas révéler si l’email existe).
- **400** pour `POST /auth/reset-password/confirm` : token invalide, expiré ou nouveau mot de passe invalide.
- Réponses structurées (ex. `{ "message": "...", "statusCode": 409 }`).

### 6. Google / Apple

- **Google** : vérifier l’`idToken` côté backend (lib `google-auth-library`) et récupérer email/nom ; créer ou récupérer l’utilisateur, lier `googleId`, puis renvoyer user + JWT.
- **Apple** : vérifier l’`identityToken` (JWT Apple), extraire `sub` (appleId) et email si fourni ; créer ou récupérer l’utilisateur, lier `appleId`, puis renvoyer user + JWT.
- En cas de premier login social : créer un utilisateur sans mot de passe (ou mot de passe aléatoire non utilisé).

### 7. Configuration

- Variables d’environnement (`.env`) :
  - `MONGODB_URI`
  - `JWT_SECRET`
  - `JWT_EXPIRES_IN`
  - Optionnel : `GOOGLE_CLIENT_ID`, `APPLE_*` si nécessaire côté backend pour la vérification des tokens.

### 8. Format de réponse API suggéré

**Succès (register / login / google / apple) :**
```json
{
  "user": {
    "id": "...",
    "name": "...",
    "email": "..."
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Erreur (ex. 409) :**
```json
{
  "statusCode": 409,
  "message": "Email already registered",
  "error": "Conflict"
}
```

---

## Checklist d’implémentation

- [ ] Projet NestJS créé (CLI `nest new`).
- [ ] MongoDB connecté (Mongoose).
- [ ] Schéma User avec fullName, email, password (hashé), googleId, appleId, timestamps.
- [ ] AuthModule + AuthController + AuthService.
- [ ] DTOs (Register, Login, ResetPassword, Google, Apple) + ValidationPipe.
- [ ] POST /auth/register : vérification email unique, hash password, création user, JWT, réponse user + accessToken.
- [ ] POST /auth/login : vérification email/password, JWT, réponse user + accessToken.
- [ ] POST /auth/reset-password : acceptation email, envoi email avec lien du type `{RESET_LINK_BASE_URL}?token=xxx` (token JWT ou UUID, validité ex. 1h).
- [ ] POST /auth/reset-password/confirm : body `{ "token": "...", "newPassword": "..." }` ; vérifier le token, trouver l’utilisateur associé, hasher et sauvegarder le nouveau mot de passe ; invalider le token ; retourner 200 ou 400 si token invalide/expiré.
- [ ] POST /auth/google : vérification idToken, création/liaison user, JWT.
- [ ] POST /auth/apple : vérification identityToken, création/liaison user, JWT.
- [ ] Guard JWT pour routes protégées (ex. GET /auth/me).
- [ ] GET /health (optionnel) : retourner `{ "status": "ok", "mongodb": "connected" }` si la base est joignable.
- [ ] CORS activé pour le client Flutter (origine autorisée).
- [ ] .env et documentation des variables.
- [ ] Tests unitaires/e2e au moins pour register et login.

---

## Résumé en une phrase

**“Crée un backend NestJS avec MongoDB qui expose des routes d’auth (register, login, reset-password, reset-password/confirm, google, apple), stocke les utilisateurs avec mot de passe hashé et des IDs sociaux optionnels, envoie un email avec lien de reset (token), et renvoie un JWT + un objet user (id, name, email) compatible avec l’app Flutter (Create Account, Sign In, Reset Password, page Nouveau mot de passe).”**

Tu peux copier ce fichier (ou ce résumé) dans ton projet NestJS et l’utiliser comme prompt pour un agent ou comme cahier des charges pour l’implémentation.
