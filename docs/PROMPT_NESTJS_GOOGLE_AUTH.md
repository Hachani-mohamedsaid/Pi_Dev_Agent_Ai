# Prompt pour NestJS – Connexion Google + JWT

Copie-colle ce bloc dans Cursor / ChatGPT / Claude pour faire implémenter le backend NestJS.

---

## Prompt

```
Backend NestJS : implémente la route POST /auth/google pour une app Flutter.

Contrat :
- Le client Flutter envoie POST /auth/google avec le body : { "idToken": "<idToken Google>" }.
- Le backend doit répondre avec : { "user": { "id", "name", "email" }, "accessToken": "<JWT>" }.

À faire :
1. Installer google-auth-library.
2. Variables d'environnement : GOOGLE_CLIENT_ID (Client ID Web de la console Google, le même que côté Flutter), JWT_SECRET, JWT_EXPIRES_IN (ex. 7d). Ne pas mettre le client_secret dans le front ; ici on vérifie uniquement l'idToken avec le Client ID.
3. DTO : GoogleAuthDto avec idToken (string, requis).
4. AuthService : méthode googleLogin(idToken) qui :
   - vérifie l'idToken avec OAuth2Client.verifyIdToken({ idToken, audience: GOOGLE_CLIENT_ID }) ;
   - extrait du payload : sub (googleId), email, name, picture ;
   - trouve ou crée l'utilisateur (findByGoogleId, sinon findByEmail pour lier le compte, sinon createFromGoogle) ;
   - génère un JWT (sub = user.id, email) avec JWT_SECRET et JWT_EXPIRES_IN ;
   - retourne { user: { id, name, email }, accessToken }.
5. AuthController : POST /auth/google qui reçoit GoogleAuthDto et appelle authService.googleLogin(dto.idToken).
6. Modèle User : champs name, email, password (optionnel), googleId, avatarUrl (ou picture). Méthodes UsersService : findByGoogleId(googleId), findByEmail(email), linkGoogleId(userId, googleId), createFromGoogle({ email, name, googleId, picture }).
7. Validation : ValidationPipe global avec whitelist. ConfigModule pour lire GOOGLE_CLIENT_ID, JWT_SECRET, JWT_EXPIRES_IN.

Référence : le code détaillé est dans docs/NESTJS_GOOGLE_AUTH_CODE.md (DTO, AuthService, AuthController, schéma User Mongoose, résumé du flux).
```

---

## Version courte (si le modèle a déjà le contexte)

```
NestJS : ajoute POST /auth/google. Body : { idToken }. Réponse : { user: { id, name, email }, accessToken }. Vérifier idToken avec google-auth-library (OAuth2Client.verifyIdToken, audience = GOOGLE_CLIENT_ID). Env : GOOGLE_CLIENT_ID, JWT_SECRET, JWT_EXPIRES_IN. findOrCreate user (googleId/email), renvoyer JWT. Voir docs/NESTJS_GOOGLE_AUTH_CODE.md pour le code complet.
```
