# Code NestJS : vérification email avec lien (Resend)

Même principe que le reset password : envoi d’un email via **Resend** avec un lien contenant un token. Au clic, l’utilisateur est redirigé vers l’app qui appelle le backend pour confirmer et passer `emailVerified` à `true`.

---

## 1. Variables d’environnement

Même config que le reset password (Resend) :

```env
RESEND_API_KEY=re_xxxxxxxxxxxx
EMAIL_FROM=onboarding@resend.dev
```

Ajouter une URL pour le lien de vérification (page Flutter / web) :

```env
# Lien de vérification email : l’app ouvrira cette URL + ?token=...
FRONTEND_VERIFY_EMAIL_URL=https://ton-app.web.app/verify-email/confirm
# En dev : http://localhost:8080/verify-email/confirm  ou  myapp://verify-email/confirm
```

---

## 2. Schéma User (MongoDB)

Ajouter les champs pour le token de vérification (ou créer un schéma dédié comme pour le reset password) :

```typescript
// Sur le schéma User (ex. src/users/schemas/user.schema.ts)
@Prop({ default: false })
emailVerified: boolean;

@Prop()
emailVerificationToken: string | null;

@Prop()
emailVerificationExpires: Date | null;
```

- À l’inscription (register) : `emailVerified: false`, pas de token.
- Après envoi de l’email de vérification : générer un token, stocker `emailVerificationToken` et `emailVerificationExpires` (ex. 24 h).
- Après confirmation (lien cliqué) : `emailVerified: true`, `emailVerificationToken = null`, `emailVerificationExpires = null`.
- Pour Google Sign-In : à la création du user, mettre `emailVerified: true`.

---

## 3. AuthService – envoi email + confirmation

Utiliser le même client **Resend** que pour le reset password.

```typescript
// auth.service.ts

/**
 * POST /auth/verify-email – envoi email avec lien (utilisateur connecté, JWT requis).
 * Utilise l’email du user associé au JWT.
 */
async sendVerificationEmail(userId: string, userEmail: string): Promise<void> {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

  await this.userModel.updateOne(
    { _id: userId },
    { $set: { emailVerificationToken: token, emailVerificationExpires: expiresAt } },
  );

  const baseUrl = this.configService.get<string>('FRONTEND_VERIFY_EMAIL_URL') ?? 'http://localhost:8080/verify-email/confirm';
  const verifyLink = `${baseUrl}?token=${token}`;
  const from = this.configService.get<string>('EMAIL_FROM') ?? 'onboarding@resend.dev';

  if (!this.resend) {
    console.warn('RESEND_API_KEY not set – verification email not sent. Link (dev):', verifyLink);
    return;
  }

  await this.resend.emails.send({
    from,
    to: [userEmail],
    subject: 'Vérifiez votre adresse email',
    html: `
      <p>Bonjour,</p>
      <p>Cliquez sur le lien ci-dessous pour vérifier votre adresse email :</p>
      <p><a href="${verifyLink}">Vérifier mon email</a></p>
      <p>Ce lien expire dans 24 heures.</p>
      <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
    `,
  });
}

/**
 * POST /auth/verify-email/confirm – token reçu depuis le lien dans l’email.
 * Met à jour le user : emailVerified = true, token supprimé.
 */
async confirmEmailVerification(token: string): Promise<void> {
  const user = await this.userModel.findOne({
    emailVerificationToken: token,
    emailVerificationExpires: { $gt: new Date() },
  });

  if (!user) {
    throw new BadRequestException('Lien invalide ou expiré');
  }

  await this.userModel.updateOne(
    { _id: user._id },
    { $set: { emailVerified: true }, $unset: { emailVerificationToken: 1, emailVerificationExpires: 1 } },
  );
}
```

---

## 4. Routes

| Méthode | Route | Body / Headers | Effet |
|--------|--------|----------------|--------|
| POST | `/auth/verify-email` | Header `Authorization: Bearer <accessToken>` | Envoi de l’email avec lien (Resend) |
| POST | `/auth/verify-email/confirm` | `{ "token": "..." }` | Confirmation et passage à `emailVerified: true` |

- **POST /auth/verify-email** : extraire le `userId` (ou l’email) du JWT, récupérer le user, appeler `sendVerificationEmail(userId, user.email)`.
- **POST /auth/verify-email/confirm** : lire `token` dans le body, appeler `confirmEmailVerification(token)`.

---

## 5. GET /auth/me

Inclure `emailVerified` dans la réponse (comme dans **NESTJS_BACKEND_PARTIE_CODE.md**) pour que l’app affiche « Verified » après confirmation.

---

## 6. Flutter

- L’app appelle **POST /auth/verify-email** avec le JWT quand l’utilisateur tape « Verify » (Privacy & Security).
- Le lien dans l’email pointe vers **FRONTEND_VERIFY_EMAIL_URL?token=...** (ex. `/verify-email/confirm?token=...`). L’app ouvre cette route, envoie le token à **POST /auth/verify-email/confirm**, puis affiche un succès et recharge le profil.
