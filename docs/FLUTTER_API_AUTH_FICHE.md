# Fiche Flutter – Consommation de l’API Auth (NestJS)

Guide pour connecter l’app Flutter à l’API d’authentification backend.

---

## 1. Base URL

L’app utilise la config dans `lib/core/config/api_config.dart` :

- **Production (Railway)** : `https://backendagentai-production.up.railway.app`
- Dev émulateur Android : `http://10.0.2.2:3000`
- Dev iOS Simulator / local : `http://localhost:3000`

---

## 2. Modèle User (côté Flutter)

Aligné sur la réponse API : `{ "id" ou "_id", "name", "email" }`.  
Voir `lib/data/models/user_model.dart` et `UserModel.fromJson` (gère `_id` MongoDB).

---

## 3. Réponse Auth (user + token)

Toutes les routes d’auth renvoient :

```json
{
  "user": { "id": "...", "name": "...", "email": "..." },
  "accessToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

Modèle : `lib/data/models/auth_response.dart` (`AuthResponse`).

---

## 4. Endpoints et implémentation

L’app appelle le backend réel via `ApiAuthRemoteDataSource` (`lib/data/datasources/auth_remote_data_source.dart`) :

| Action Flutter   | Méthode | Route                | Body / Header                    |
|------------------|--------|----------------------|----------------------------------|
| Inscription      | POST   | `/auth/register`     | name, email, password            |
| Connexion        | POST   | `/auth/login`        | email, password                  |
| Reset password   | POST   | `/auth/reset-password` | email                         |
| Connexion Google | POST   | `/auth/google`       | idToken                          |
| Connexion Apple  | POST   | `/auth/apple`        | identityToken, user?             |
| Profil (moi)     | GET    | `/auth/me`           | Header: `Authorization: Bearer <token>` |

---

## 5. Stockage du token

- **shared_preferences** : token et user en cache (voir `SharedPreferencesAuthLocalDataSource`).
- Après `register` / `login` / Google / Apple : `accessToken` et user sont sauvegardés.
- Pour les requêtes protégées (ex. `GET /auth/me`), le token est lu et envoyé en `Authorization: Bearer <token>`.

---

## 6. Codes d’erreur courants

| Code   | Signification |
|--------|----------------|
| 200/201 | Succès |
| 400    | Données invalides (validation) |
| 401    | Identifiants incorrects ou token invalide/expiré |
| 409    | Email déjà utilisé (inscription) |

---

## 7. CORS et émulateur

- Backend : CORS activé pour l’origine du client.
- Émulateur Android : utiliser `http://10.0.2.2:3000` au lieu de `localhost:3000`.
- App physique : utiliser l’URL Railway en prod ou l’IP de la machine en dev.
