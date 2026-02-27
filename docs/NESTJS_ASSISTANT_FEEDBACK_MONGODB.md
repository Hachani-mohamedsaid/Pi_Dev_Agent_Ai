# NestJS – Stocker le feedback Suggestions (Accepter / Refuser) dans MongoDB

Quand l’utilisateur clique sur **Accepter** ou **Refuser** sur une carte suggestion, l’app Flutter envoie un **POST /assistant/feedback** au backend. Ce document décrit comment **persister ce feedback dans la collection `assistant_feedback`** pour l’apprentissage et les stats.

---

## 1. Contrat envoyé par Flutter

- **Méthode :** `POST`
- **URL :** `{baseUrl}/assistant/feedback`
- **Headers :** `Content-Type: application/json`, `Authorization: Bearer <accessToken>` (si utilisateur connecté)
- **Body (JSON) :**
```json
{
  "suggestionId": "674abc... ou openai_1738...",
  "action": "accepted | dismissed",
  "userId": "id_utilisateur_ou_vide",
  "message": "How about a quick walk outside to soak up the sun?",
  "type": "leave_home"
}
```
- **Champs :**
  - `suggestionId` (string) : id de la suggestion (ObjectId du backend ou `openai_*` si générée côté client).
  - `action` (string) : `"accepted"` ou `"dismissed"`.
  - `userId` (string, optionnel) : identifiant utilisateur (pour associer le feedback).
  - `message` (string, optionnel) : texte de la suggestion (utile si suggestion d’origine client).
  - `type` (string, optionnel) : type de suggestion (ex. `leave_home`, `break`, `coffee`).
- **Réponse succès :** status `200` (body optionnel, ex. `{ "ok": true }`).

**Important :** le backend doit **toujours** enregistrer le feedback dans `assistant_feedback`, même si `suggestionId` est un id côté client (ex. `openai_*`) et n’existe pas dans `assistant_suggestions`. Cela permet d’avoir des données d’apprentissage pour toutes les interactions.

---

## 2. Schéma Mongoose

Crée le fichier **`src/assistant/schemas/assistant-feedback.schema.ts`** (ou équivalent) :

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AssistantFeedbackDocument = AssistantFeedback & Document;

@Schema({ timestamps: true, collection: 'assistant_feedback' })
export class AssistantFeedback {
  @Prop({ required: true })
  suggestionId: string;

  @Prop({ required: true, enum: ['accepted', 'dismissed'] })
  action: string;

  @Prop({ default: null })
  userId?: string;

  @Prop({ default: null })
  message?: string;

  @Prop({ default: null })
  type?: string;

  @Prop({ default: Date.now })
  createdAt: Date;
}

export const AssistantFeedbackSchema = SchemaFactory.createForClass(AssistantFeedback);
```

---

## 3. DTO

**`src/assistant/dto/assistant-feedback.dto.ts`** :

```typescript
import { IsString, IsOptional, IsIn } from 'class-validator';

export class AssistantFeedbackDto {
  @IsString()
  suggestionId: string;

  @IsString()
  @IsIn(['accepted', 'dismissed'])
  action: string;

  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsString()
  message?: string;

  @IsOptional()
  @IsString()
  type?: string;
}
```

---

## 4. Service – insertion en base

**`src/assistant/assistant.service.ts`** (extrait) :

```typescript
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { AssistantFeedback, AssistantFeedbackDocument } from './schemas/assistant-feedback.schema';
import { AssistantFeedbackDto } from './dto/assistant-feedback.dto';

@Injectable()
export class AssistantService {
  constructor(
    @InjectModel(AssistantFeedback.name)
    private assistantFeedbackModel: Model<AssistantFeedbackDocument>,
  ) {}

  async saveFeedback(dto: AssistantFeedbackDto): Promise<void> {
    await this.assistantFeedbackModel.create({
      suggestionId: dto.suggestionId,
      action: dto.action,
      userId: dto.userId ?? null,
      message: dto.message ?? null,
      type: dto.type ?? null,
    });
  }
}
```

---

## 5. Controller – route protégée

**`src/assistant/assistant.controller.ts`** (extrait) :

```typescript
import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator'; // ou équivalent
import { AssistantService } from './assistant.service';
import { AssistantFeedbackDto } from './dto/assistant-feedback.dto';

@Controller('assistant')
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  @Post('feedback')
  @UseGuards(JwtAuthGuard)
  async feedback(
    @Body() dto: AssistantFeedbackDto,
    @CurrentUser() user?: { id: string },
  ) {
    const userId = dto.userId ?? user?.id ?? null;
    await this.assistantService.saveFeedback({
      ...dto,
      userId: userId ?? dto.userId,
    });
    return { ok: true };
  }
}
```

Si tu préfères une route **publique** (sans JWT), enlève `@UseGuards(JwtAuthGuard)` et utilise uniquement `dto.userId` pour stocker.

---

## 6. Module

- Enregistre le schéma `AssistantFeedback` dans le module (ex. `AssistantModule`).
- Importe `MongooseModule.forFeature([{ name: AssistantFeedback.name, schema: AssistantFeedbackSchema }])`.
- Expose `AssistantService` et `AssistantController`.

---

## 7. Checklist

| # | Élément | Fait |
|---|---------|------|
| 1 | Schéma Mongoose `assistant_feedback` (suggestionId, action, userId?, message?, type?, createdAt) | |
| 2 | DTO avec validation (suggestionId, action, userId?, message?, type?) | |
| 3 | POST /assistant/feedback qui insère un document dans la collection | |
| 4 | Route protégée par JWT (optionnel) et récupération userId si absent du body | |

Une fois en place, chaque clic **Accepter** ou **Refuser** dans l’app Flutter créera un document dans `assistant_feedback` dans MongoDB (visible dans Atlas → Data Explorer → `assistant_feedback`).
