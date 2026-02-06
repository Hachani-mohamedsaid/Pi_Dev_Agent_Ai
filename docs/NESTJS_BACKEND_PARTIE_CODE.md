# Partie backend NestJS – Code pour l’app Flutter

Ce document regroupe le **code backend** à ajouter ou adapter pour que l’app Flutter (auth, profil, chat IA, email verification) fonctionne correctement.

---

## 1. GET /auth/me – inclure `emailVerified`

L’app affiche « Email Verification » / « Verified » dans Privacy & Security. Il faut renvoyer `emailVerified` dans le profil.

### Option A : champ sur le schéma User (MongoDB)

```typescript
// src/users/schemas/user.schema.ts (ajout)
@Prop({ default: false })
emailVerified: boolean;
```

- À la création du user (register) : `emailVerified: false`.
- Après envoi + clic sur lien de vérification email : mettre `emailVerified: true` (il faut une route du type `GET /auth/verify-email?token=...` et un champ `emailVerificationToken` / `emailVerificationExpires` si tu veux une vraie vérification).
- Pour Google Sign-In : à la création du user depuis Google, mettre `emailVerified: true` (Google a déjà vérifié l’email).

### Réponse GET /auth/me

Le contrôleur qui gère GET /auth/me doit renvoyer un objet qui contient au minimum les champs attendus par Flutter (voir `ProfileModel`), dont **emailVerified** :

```typescript
// Exemple dans auth.controller.ts ou users.controller.ts
@Get('me')
@UseGuards(JwtAuthGuard)
async getProfile(@Request() req: { user: { sub: string } }) {
  const user = await this.usersService.findById(req.user.sub);
  if (!user) throw new UnauthorizedException();
  return {
    id: user._id.toString(),
    name: user.name,
    email: user.email,
    avatarUrl: user.avatarUrl,
    role: user.role,
    location: user.location,
    phone: user.phone,
    birthDate: user.birthDate,
    bio: user.bio,
    createdAt: user.createdAt,
    conversationsCount: user.conversationsCount ?? 0,
    daysActive: user.daysActive ?? 0,
    hoursSaved: user.hoursSaved ?? 0,
    emailVerified: user.emailVerified ?? true, // true par défaut si pas encore de logique
  };
}
```

Sans logique de vérification email, tu peux renvoyer `emailVerified: true` pour tous les users connectés.

---

## 2. POST /ai/chat – JWT + contexte utilisateur + LLM

L’app envoie les messages (dont un éventuel message **system** pour la langue) et le header **Authorization: Bearer &lt;accessToken&gt;**. Le backend doit : valider le JWT, récupérer l’utilisateur, enrichir le system avec nom/email, appeler le LLM, renvoyer la réponse.

### DTO

```typescript
// src/ai/dto/chat.dto.ts
import { IsArray, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ChatMessageDto {
  @IsString()
  role: string; // 'system' | 'user' | 'assistant'

  @IsString()
  content: string;
}

export class ChatBodyDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChatMessageDto)
  messages: ChatMessageDto[];
}
```

### Service AI (exemple avec OpenAI)

```typescript
// src/ai/ai.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import OpenAI from 'openai';

@Injectable()
export class AiService {
  private openai: OpenAI | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly usersService: UsersService,
  ) {
    const key = this.config.get<string>('OPENAI_API_KEY');
    if (key) this.openai = new OpenAI({ apiKey: key });
  }

  async chat(messages: { role: string; content: string }[], userId?: string): Promise<string> {
    const systemParts: string[] = [];

    if (userId) {
      const user = await this.usersService.findById(userId);
      if (user?.name || user?.email) {
        systemParts.push(
          `L'utilisateur connecté est : prénom/nom = ${user.name ?? 'inconnu'}, email = ${user.email ?? 'inconnu'}. ` +
          `Quand l'utilisateur demande son nom, son identité ou « qui je suis », utilise ces informations pour répondre.`,
        );
      }
    }

    const systemFromFront = messages.find((m) => m.role === 'system')?.content;
    if (systemFromFront) systemParts.push(systemFromFront);

    const systemContent = systemParts.join('\n');
    const filtered = messages.filter((m) => m.role !== 'system');
    const openaiMessages: OpenAI.Chat.ChatCompletionMessageParam[] = [
      { role: 'system', content: systemContent || 'You are a helpful assistant.' },
      ...filtered.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
    ];

    if (!this.openai) throw new Error('OPENAI_API_KEY not set');
    const completion = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: openaiMessages,
    });
    const text = completion.choices[0]?.message?.content?.trim();
    if (!text) throw new Error('Empty response from LLM');
    return text;
  }
}
```

### Controller

```typescript
// src/ai/ai.controller.ts
import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AiService } from './ai.service';
import { ChatBodyDto } from './dto/chat.dto';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat')
  @UseGuards(JwtAuthGuard) // optionnel : si présent, req.user est défini
  async chat(
    @Body() body: ChatBodyDto,
    @Req() req: { user?: { sub: string } },
  ) {
    const userId = req.user?.sub;
    const content = await this.aiService.chat(body.messages, userId);
    return { message: content };
  }
}
```

Si tu ne veux pas rendre la route protégée, enlève `@UseGuards(JwtAuthGuard)` et passe `undefined` comme `userId` (l’assistant ne pourra pas dire « qui est l’utilisateur »).

### Variables d’environnement

```env
OPENAI_API_KEY=sk-xxxxxxxx
```

### Dépendance

```bash
npm install openai
```

---

## 3. Résumé des routes utilisées par Flutter

| Méthode | Route | Rôle |
|--------|--------|------|
| POST | `/auth/login` | Connexion email/mot de passe |
| POST | `/auth/register` | Inscription |
| POST | `/auth/google` | Connexion avec idToken Google |
| POST | `/auth/reset-password` | Demande de reset (envoi email Resend) |
| POST | `/auth/reset-password/confirm` | Confirmation avec token + newPassword |
| GET | `/auth/me` | Profil (avec **emailVerified**) |
| POST | `/auth/change-password` | Changement mot de passe (JWT requis) |
| POST | `/ai/chat` | Chat IA (JWT optionnel, body **messages** ; réponse **message** ou **content**) |

---

## 4. Realtime Voice (voix ChatGPT originale)

Pour la voix temps réel type ChatGPT, voir le document **NESTJS_REALTIME_VOICE_OPENAI.md** (proxy WebSocket vers l’API OpenAI Realtime). Ce document décrit le service + gateway NestJS et l’URL attendue par Flutter (`realtimeVoiceWsUrl`).

---

## 5. Références

- **CONFIGURATION_NESTJS_BACKEND.md** : variables d’environnement, checklist, contexte /ai/chat.
- **NESTJS_GOOGLE_AUTH_CODE.md** : code Google Sign-In.
- **NESTJS_EMAIL_RESET_PASSWORD_CODE.md** : code reset password avec Resend.
