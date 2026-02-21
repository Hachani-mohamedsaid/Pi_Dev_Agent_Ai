# NestJS – Module Advisor (simulation financière + historique)

Ce document décrit comment intégrer le module **AI Financial Simulation Advisor** (analyse + **historique**) dans un backend **NestJS** avec MongoDB.

---

## 1. Vue d’ensemble

L’app Flutter appelle :

| Méthode | Route | Rôle |
|--------|--------|------|
| `POST` | `/api/advisor/analyze` | Envoyer un texte projet → n8n → rapport → sauvegarde en base → retour du rapport |
| `GET`  | `/api/advisor/history` | Récupérer la liste des analyses (historique) de l’utilisateur connecté |

- **Analyze** : body `{ "project_text": "string" }`, réponse `{ "report": "string" }`.
- **History** : en-tête optionnel `Authorization: Bearer <JWT>`. Réponse `{ "analyses": [ { "id", "project_text", "report", "createdAt" }, ... ] }`.

---

## 2. Collection MongoDB `analyses`

Une seule collection, pas besoin de modifier les modèles existants.

**Nom :** `analyses` (ou le nom que vous donnez au schéma Mongoose).

**Champs :**

| Champ          | Type   | Obligatoire | Description                          |
|----------------|--------|-------------|--------------------------------------|
| `userId`       | string | Non         | ID utilisateur (JWT). Vide si non connecté. |
| `project_text` | string | Oui         | Texte du projet envoyé par l’utilisateur.   |
| `report`       | string | Oui         | Rapport renvoyé par le webhook n8n.         |
| `createdAt`    | Date   | Oui         | Date de création de l’analyse.             |

**Index recommandé :**  
`{ userId: 1, createdAt: -1 }` pour les requêtes d’historique par utilisateur.

---

## 3. Structure NestJS proposée

```
src/
  advisor/
    advisor.module.ts
    advisor.controller.ts
    advisor.service.ts
    dto/
      analyze.dto.ts
    schemas/
      analysis.schema.ts   (Mongoose)
```

---

## 4. Schéma Mongoose (analysis.schema.ts)

```typescript
// src/advisor/schemas/analysis.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AnalysisDocument = Analysis & Document;

@Schema({ collection: 'analyses', timestamps: true })
export class Analysis {
  @Prop({ required: false, index: true })
  userId?: string;

  @Prop({ required: true })
  project_text: string;

  @Prop({ required: true })
  report: string;

  @Prop({ default: () => new Date() })
  createdAt: Date;
}

export const AnalysisSchema = SchemaFactory.createForClass(Analysis);

// Index pour l’historique par utilisateur
AnalysisSchema.index({ userId: 1, createdAt: -1 });
```

---

## 5. DTO (analyze.dto.ts)

```typescript
// src/advisor/dto/analyze.dto.ts
import { IsString, IsNotEmpty, MaxLength } from 'class-validator';

export class AnalyzeAdvisorDto {
  @IsString()
  @IsNotEmpty({ message: 'project_text is required' })
  @MaxLength(10000)
  project_text: string;
}
```

---

## 6. Service (advisor.service.ts)

Le service appelle le webhook n8n puis enregistre en base. Utilisez `axios` ou `HttpService` (NestJS).

```typescript
// src/advisor/advisor.service.ts
import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';
import { Analysis, AnalysisDocument } from './schemas/analysis.schema';

const N8N_WEBHOOK_URL =
  process.env.ADVISOR_N8N_WEBHOOK_URL ||
  'https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c';

const TIMEOUT_MS = 90000;

@Injectable()
export class AdvisorService {
  constructor(
    @InjectModel(Analysis.name) private analysisModel: Model<AnalysisDocument>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  async sendProjectToAdvisor(text: string): Promise<{ report: string }> {
    const url = this.configService.get<string>('ADVISOR_N8N_WEBHOOK_URL') || N8N_WEBHOOK_URL;
    try {
      const response = await firstValueFrom(
        this.httpService.post(
          url,
          { text: text.trim() },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: TIMEOUT_MS,
          },
        ),
      );
      const report = response.data?.report;
      if (report == null || typeof report !== 'string') {
        throw new Error('Invalid n8n response: missing or invalid report');
      }
      return { report };
    } catch (err: any) {
      if (err.code === 'ECONNABORTED') {
        throw new HttpException('Request timeout. Please try again.', HttpStatus.GATEWAY_TIMEOUT);
      }
      const status = err.response?.status;
      const message =
        status >= 500 ? 'Server error. Try again later.' : (err.message || 'Analysis failed');
      throw new HttpException(message, status >= 500 ? HttpStatus.BAD_GATEWAY : HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  async analyze(projectText: string, userId?: string): Promise<{ report: string }> {
    const { report } = await this.sendProjectToAdvisor(projectText);

    await this.analysisModel.create({
      userId: userId || undefined,
      project_text: projectText.trim(),
      report,
      createdAt: new Date(),
    });

    return { report };
  }

  async getHistory(userId?: string): Promise<{ id: string; project_text: string; report: string; createdAt: Date }[]> {
    const filter = userId ? { userId } : {};
    const docs = await this.analysisModel
      .find(filter)
      .sort({ createdAt: -1 })
      .limit(50)
      .select('project_text report createdAt')
      .lean()
      .exec();

    return docs.map((d: any) => ({
      id: d._id.toString(),
      project_text: d.project_text ?? '',
      report: d.report ?? '',
      createdAt: d.createdAt,
    }));
  }
}
```

---

## 7. Controller (advisor.controller.ts)

- **POST /api/advisor/analyze** : body validé par `AnalyzeAdvisorDto`, utilisateur optionnel (JWT).
- **GET /api/advisor/history** : utilisateur optionnel (JWT) ; si présent, on filtre par `userId`.

```typescript
// src/advisor/advisor.controller.ts
import { Controller, Post, Get, Body, UseGuards, Request } from '@nestjs/common';
import { AdvisorService } from './advisor.service';
import { AnalyzeAdvisorDto } from './dto/analyze.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // à adapter à votre auth

@Controller('api/advisor')
export class AdvisorController {
  constructor(private readonly advisorService: AdvisorService) {}

  @Post('analyze')
  async analyze(@Body() dto: AnalyzeAdvisorDto, @Request() req: any) {
    const userId = req.user?.sub ?? req.user?.id ?? undefined;
    return this.advisorService.analyze(dto.project_text, userId);
  }

  @Get('history')
  async getHistory(@Request() req: any) {
    const userId = req.user?.sub ?? req.user?.id ?? undefined;
    const analyses = await this.advisorService.getHistory(userId);
    return { analyses };
  }
}
```

Si vous ne voulez pas protéger les routes par JWT, enlevez `@UseGuards(JwtAuthGuard)` et laissez `req.user` à `undefined` : l’historique retournera alors toutes les analyses (ou une liste vide si vous filtrez quand même par `userId` côté service).

Pour **protéger** et récupérer l’utilisateur :

```typescript
@UseGuards(JwtAuthGuard)
@Get('history')
async getHistory(@Request() req: any) {
  const userId = req.user?.sub ?? req.user?.id;
  const analyses = await this.advisorService.getHistory(userId);
  return { analyses };
}
```

---

## 8. Module (advisor.module.ts)

```typescript
// src/advisor/advisor.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { AdvisorController } from './advisor.controller';
import { AdvisorService } from './advisor.service';
import { Analysis, AnalysisSchema } from './schemas/analysis.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Analysis.name, schema: AnalysisSchema }]),
    HttpModule.register({ timeout: 90000, maxRedirects: 5 }),
  ],
  controllers: [AdvisorController],
  providers: [AdvisorService],
  exports: [AdvisorService],
})
export class AdvisorModule {}
```

Enregistrer `AdvisorModule` dans `AppModule` (imports).

---

## 9. Variables d’environnement

Dans votre `.env` (ou config NestJS) :

```env
# Optionnel : URL du webhook n8n (simulation financière)
ADVISOR_N8N_WEBHOOK_URL=https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c
```

---

## 10. Contrat API (rappel)

### POST /api/advisor/analyze

- **Body :** `{ "project_text": "string" }`
- **Réponse 200 :** `{ "report": "string" }`
- **Erreurs :** 400 (project_text manquant ou invalide), 504 (timeout), 500/502 (erreur serveur / n8n)

### GET /api/advisor/history

- **Headers :** `Authorization: Bearer <JWT>` (optionnel)
- **Réponse 200 :**  
  `{ "analyses": [ { "id": "...", "project_text": "...", "report": "...", "createdAt": "..." }, ... ] }`
- Tri : `createdAt` décroissant. Limite conseillée : 50 entrées.
- Si JWT présent : filtrer par `userId` (ou équivalent) pour ne retourner que l’historique de l’utilisateur connecté.

---

## 11. Flutter

L’app utilise :

- `apiBaseUrl + '/api/advisor/analyze'` pour la simulation.
- `apiBaseUrl + '/api/advisor/history'` pour l’historique, avec en-tête `Authorization: Bearer <token>` si l’utilisateur est connecté.

Une fois ce module NestJS en place et hébergé, il suffit que `apiBaseUrl` pointe vers votre backend NestJS pour que l’historique et l’analyse fonctionnent.

---

## 12. Dépannage : « Aucune simulation enregistrée » alors que MongoDB contient des analyses

Si des documents existent dans la collection `analyses` mais que l’app affiche un historique vide :

1. **Vérifier que GET /api/advisor/history est bien déployé**  
   L’app appelle `GET {apiBaseUrl}/api/advisor/history`. Si cette route n’existe pas sur le backend (ex. Railway), la réponse est 404 et l’app affiche une liste vide. Il faut implémenter et déployer la route (voir sections 4–7).

2. **Format de la réponse**  
   Le backend doit renvoyer au minimum :  
   `{ "analyses": [ { "id" ou "_id", "project_text", "report", "createdAt" }, ... ] }`.  
   L’app accepte aussi un tableau à la racine : `[ { ... }, ... ]`.

3. **Filtre par utilisateur**  
   Si vous filtrez par `userId` (quand un JWT est présent), les documents sans `userId` ne sont pas retournés. Pour que les anciennes analyses (sans user) apparaissent, vous pouvez :
   - soit ne pas filtrer quand il n’y a pas de JWT,
   - soit inclure aussi les documents où `userId` est absent ou null.

4. **Tester la route**  
   Depuis un navigateur ou Postman :  
   `GET https://votre-backend.up.railway.app/api/advisor/history`  
   Vous devez voir un JSON avec un tableau `analyses` (même vide). Si vous avez une 404, la route n’est pas exposée sur ce backend.
