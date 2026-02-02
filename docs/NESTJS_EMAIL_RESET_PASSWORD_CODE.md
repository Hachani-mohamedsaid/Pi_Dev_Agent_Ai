# Code NestJS : envoi email Reset Password (Resend, sans SendGrid / SMTP)

Code à intégrer dans ton backend NestJS pour **POST /auth/reset-password** (envoi du lien par email) et **POST /auth/reset-password/confirm**, en utilisant **Resend** (API uniquement, pas SendGrid, pas SMTP).

---

## 1. Dépendances

```bash
npm install resend
# ou si tu préfères tout en HTTP : npm install axios
```

---

## 2. Variables d'environnement (.env)

```env
# Email – Resend (pas SendGrid, pas SMTP)
RESEND_API_KEY=re_xxxxxxxxxxxx
EMAIL_FROM=onboarding@resend.dev

# URL du front Flutter – page confirm avec ?token=...
FRONTEND_RESET_PASSWORD_URL=http://localhost:7357/reset-password/confirm
# En prod : https://ton-app.web.app/reset-password/confirm
```

---

## 3. Modèle / stockage du token reset (MongoDB)

**Schéma Mongoose – `PasswordResetToken` (ou intégré dans User)**

```typescript
// src/auth/schemas/password-reset-token.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class PasswordResetToken extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  token: string;

  @Prop({ required: true })
  expiresAt: Date;
}

export const PasswordResetTokenSchema = SchemaFactory.createForClass(PasswordResetToken);
PasswordResetTokenSchema.index({ token: 1 }, { unique: true });
PasswordResetTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL
```

---

## 4. AuthService – requestPasswordReset + envoi email Resend

```typescript
// Dans auth.service.ts
import { Resend } from 'resend';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as crypto from 'crypto';
import { PasswordResetToken } from './schemas/password-reset-token.schema';

@Injectable()
export class AuthService {
  private resend: Resend;

  constructor(
    private readonly configService: ConfigService,
    @InjectModel(PasswordResetToken.name) private readonly resetTokenModel: Model<PasswordResetToken>,
    // ... autres injections (UsersService, JwtService, etc.)
  ) {
    const apiKey = this.configService.get<string>('RESEND_API_KEY');
    this.resend = apiKey ? new Resend(apiKey) : (null as any);
  }

  /**
   * POST /auth/reset-password – envoi email avec lien (Resend, pas SendGrid/SMTP).
   */
  async requestPasswordReset(email: string): Promise<void> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Ne pas révéler si l'email existe (sécurité)
      return;
    }

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1h

    await this.resetTokenModel.create({
      userId: user.id,
      token,
      expiresAt,
    });

    const baseUrl = this.configService.get<string>('FRONTEND_RESET_PASSWORD_URL') ?? 'http://localhost:7357/reset-password/confirm';
    const resetLink = `${baseUrl}?token=${token}`;
    const from = this.configService.get<string>('EMAIL_FROM') ?? 'onboarding@resend.dev';

    if (!this.resend) {
      console.warn('RESEND_API_KEY not set – email not sent. Reset link (dev):', resetLink);
      return;
    }

    await this.resend.emails.send({
      from,
      to: [email],
      subject: 'Réinitialisation de votre mot de passe',
      html: `
        <p>Bonjour,</p>
        <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
        <p><a href="${resetLink}">Cliquez ici pour définir un nouveau mot de passe</a></p>
        <p>Ce lien expire dans 1 heure.</p>
        <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
      `,
    });
  }

  /**
   * POST /auth/reset-password/confirm – token + newPassword.
   */
  async confirmResetPassword(token: string, newPassword: string): Promise<void> {
    const record = await this.resetTokenModel
      .findOne({ token, expiresAt: { $gt: new Date() } })
      .populate('userId')
      .exec();

    if (!record) {
      throw new BadRequestException('Token invalide ou expiré');
    }

    const user = await this.usersService.findById((record.userId as any)._id);
    if (!user) {
      throw new BadRequestException('Utilisateur introuvable');
    }

    await this.usersService.updatePassword(user.id, newPassword); // à implémenter (hash bcrypt)
    await this.resetTokenModel.deleteOne({ token }).exec();
  }
}
```

---

## 5. Envoi en HTTP pur (sans package `resend`)

Si tu ne veux pas installer le package `resend`, tu peux envoyer l’email avec `axios` :

```typescript
import axios from 'axios';

async sendResetEmail(email: string, resetLink: string): Promise<void> {
  const apiKey = this.configService.get<string>('RESEND_API_KEY');
  const from = this.configService.get<string>('EMAIL_FROM') ?? 'onboarding@resend.dev';
  if (!apiKey) return;

  await axios.post(
    'https://api.resend.com/emails',
    {
      from,
      to: [email],
      subject: 'Réinitialisation de votre mot de passe',
      html: `<p><a href="${resetLink}">Réinitialiser le mot de passe</a></p>`,
    },
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
    },
  );
}
```

---

## 6. Résumé

- **Pas de SendGrid** : utilisation de **Resend** (ou Brevo) avec une clé API.
- **Pas de SMTP** : envoi via **API HTTP** Resend (`https://api.resend.com/emails`).
- **Reset password** : génération d’un token, stockage en base avec TTL 1h, envoi de l’email avec `FRONTEND_RESET_PASSWORD_URL?token=...`, puis traitement du token dans **POST /auth/reset-password/confirm**.

Flutter n’a pas besoin d’être modifié : il appelle déjà **POST /auth/reset-password** et **POST /auth/reset-password/confirm** avec le token récupéré depuis l’URL.
