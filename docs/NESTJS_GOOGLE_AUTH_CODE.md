# Code NestJS pour POST /auth/google (vérification idToken + JWT)

Ce document contient le **code réel** à ajouter dans ton backend NestJS (y compris sur Railway) pour que la connexion Google fonctionne avec le Flutter. Le Flutter envoie déjà `POST /auth/google` avec `{ "idToken": "..." }` et attend `{ "user": { "id", "name", "email" }, "accessToken": "..." }`.

---

## 1. Dépendances

Dans ton projet NestJS :

```bash
npm install google-auth-library
# Déjà présents en général : @nestjs/jwt @nestjs/passport passport-jwt
```

---

## 2. Variables d'environnement (.env)

Utilise le **même Client ID** que dans la console Google (Web application) et dans Flutter. Ne mets **jamais** le Client Secret dans le front ; ici on ne fait que vérifier l’idToken, le Client ID suffit.

```env
GOOGLE_CLIENT_ID=1089118476895-i9cgjpn49347f6rrtgi1t27ehttb3oh6.apps.googleusercontent.com
JWT_SECRET=ton_secret_jwt_fort_et_long
JWT_EXPIRES_IN=7d
```

Sur Railway : ajoute ces variables dans **Variables** du service.

---

## 3. DTO – Google Auth

**Fichier : `src/auth/dto/google-auth.dto.ts`**

```typescript
import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleAuthDto {
  @IsString()
  @IsNotEmpty()
  idToken: string;
}
```

---

## 4. AuthService – vérification idToken + findOrCreate + JWT

**Fichier : `src/auth/auth.service.ts`**

Ajoute l’import et le constructeur pour `OAuth2Client`, puis la méthode `googleLogin` :

```typescript
import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';

// Dans le constructeur, injecte ConfigService pour GOOGLE_CLIENT_ID et JWT
constructor(
  private readonly usersService: UsersService,  // ou ton service User
  private readonly jwtService: JwtService,
  private readonly configService: ConfigService,
) {}

/**
 * Connexion Google : vérifie l'idToken, récupère ou crée l'utilisateur, renvoie user + JWT.
 * Contrat Flutter : { user: { id, name, email }, accessToken }
 */
async googleLogin(idToken: string): Promise<{ user: any; accessToken: string }> {
  const clientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
  if (!clientId) {
    throw new UnauthorizedException('GOOGLE_CLIENT_ID not configured');
  }

  const client = new OAuth2Client(clientId);
  let ticket;
  try {
    ticket = await client.verifyIdToken({
      idToken,
      audience: clientId,
    });
  } catch {
    throw new UnauthorizedException('Invalid Google idToken');
  }

  const payload = ticket.getPayload();
  if (!payload || !payload.email) {
    throw new UnauthorizedException('Google token missing email');
  }

  const googleId = payload.sub;
  const email = payload.email;
  const name = payload.name ?? payload.email.split('@')[0];
  const picture = payload.picture ?? undefined;

  // Trouver ou créer l'utilisateur (à adapter selon ton UsersService / schéma)
  let user = await this.usersService.findByGoogleId(googleId);
  if (!user) {
    user = await this.usersService.findByEmail(email);
    if (user) {
      // Lier le compte existant à Google
      await this.usersService.linkGoogleId(user.id, googleId);
    } else {
      user = await this.usersService.createFromGoogle({
        email,
        name,
        googleId,
        picture,
      });
    }
  }

  const accessToken = this.jwtService.sign(
    { sub: user.id, email: user.email },
    {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: this.configService.get<string>('JWT_EXPIRES_IN') ?? '7d',
    },
  );

  return {
    user: {
      id: user.id.toString(),
      name: user.name,
      email: user.email,
    },
    accessToken,
  };
}
```

À adapter selon ton modèle User :
- `usersService.findByGoogleId(googleId)`
- `usersService.findByEmail(email)`
- `usersService.linkGoogleId(userId, googleId)` (optionnel)
- `usersService.createFromGoogle({ email, name, googleId, picture })` (créer sans mot de passe)

Exemple **createFromGoogle** (si tu utilises Mongoose) :

```typescript
async createFromGoogle(data: {
  email: string;
  name: string;
  googleId: string;
  picture?: string;
}) {
  const user = await this.userModel.create({
    email: data.email,
    name: data.name,
    googleId: data.googleId,
    avatarUrl: data.picture,
    // pas de password ou password hashé aléatoire jamais utilisé
  });
  return user;
}
```

---

## 5. AuthController – route POST /auth/google

**Fichier : `src/auth/auth.controller.ts`**

```typescript
import { GoogleAuthDto } from './dto/google-auth.dto';

@Post('google')
async googleLogin(@Body() dto: GoogleAuthDto) {
  return this.authService.googleLogin(dto.idToken);
}
```

Assure-toi que le body soit validé (ValidationPipe global avec `whitelist: true`).

---

## 6. Schéma User (Mongoose) – champs utiles pour Google

**Exemple : `src/users/user.schema.ts` (ou auth)**

```typescript
@Schema({ timestamps: true })
export class User {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop()
  password?: string; // optionnel si inscription uniquement via Google

  @Prop()
  googleId?: string;

  @Prop()
  appleId?: string;

  @Prop()
  avatarUrl?: string;
}
```

Dans ton `UsersService` :

```typescript
async findByGoogleId(googleId: string) {
  return this.userModel.findOne({ googleId }).exec();
}
async findByEmail(email: string) {
  return this.userModel.findOne({ email }).exec();
}
async linkGoogleId(userId: string, googleId: string) {
  await this.userModel.updateOne({ _id: userId }, { googleId }).exec();
}
```

---

## 7. Résumé du flux

| Étape | Côté Flutter | Côté NestJS |
|-------|--------------|-------------|
| 1 | Utilisateur clique « Google Account » | — |
| 2 | Google renvoie un `idToken` (JWT) | — |
| 3 | `POST /auth/google` avec `{ "idToken": "..." }` | Reçu par `AuthController` |
| 4 | — | `OAuth2Client.verifyIdToken(idToken, audience: GOOGLE_CLIENT_ID)` |
| 5 | — | Extraction email, name, sub (googleId) du payload |
| 6 | — | findOrCreate user, génération JWT |
| 7 | Réponse `{ user, accessToken }` | Envoi 200 + JSON |
| 8 | Stockage `accessToken`, redirection | — |

---

## 8. Module et Config (NestJS)

- **ConfigModule** : pour utiliser `ConfigService` et `GOOGLE_CLIENT_ID`, enregistre `ConfigModule.forRoot()` dans `AppModule` (ou `AuthModule`).
- **AuthModule** : importe `JwtModule.registerAsync(...)` avec `JWT_SECRET` et `JWT_EXPIRES_IN` depuis `ConfigService`, et `UsersModule` (ou ton module User).

---

## 9. Railway + Flutter

- **Backend (Railway)** : onglet **Variables** → `GOOGLE_CLIENT_ID`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `MONGODB_URI`.
- **Flutter** : `lib/core/config/api_config.dart` → `baseUrl` / `apiBaseUrl` doit pointer vers l’URL Railway (ex. `https://backendagentai-production.up.railway.app`). C’est déjà le cas dans ton projet.
- **Google Console** : **Origines JavaScript autorisées** = `http://localhost`, `http://localhost:7357` (dev) et en prod l’URL de ton app Flutter web (ex. `https://ton-app.web.app`). Le backend n’a pas besoin d’être ajouté aux origines.

Une fois ce code en place, le bouton « Google Account » dans Flutter envoie l’idToken au backend NestJS (y compris sur Railway), qui le vérifie et renvoie `user` + `accessToken` au format attendu par l’app.
