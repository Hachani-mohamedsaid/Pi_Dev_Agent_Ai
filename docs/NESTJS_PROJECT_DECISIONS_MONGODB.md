# NestJS – Stocker les décisions Propositions (Accepter / Rejeter) dans MongoDB

Quand l’utilisateur clique sur **Accepter** ou **Rejeter** sur une carte proposition, l’app Flutter envoie un POST à ton backend NestJS. Ce document décrit le code à ajouter pour **persister ces décisions dans MongoDB** avec Mongoose.

---

## 1. Endpoint attendu par Flutter

- **Méthode :** `POST`
- **URL :** `{baseUrl}/project-decisions`
- **Headers :** `Content-Type: application/json`
- **Body (JSON) :**
```json
{
  "action": "accept" | "reject",
  "row_number": 5,
  "name": "Mohamed said Hachani",
  "email": "mohamedsaidhachani93274190@gmail.com",
  "type_projet": "application mobile"
}
```
- **Réponse succès :** status `200` (body optionnel, ex. `{ "ok": true }`).

**Récupération des décisions (pour que l’app restaure Acceptée/Rejetée au redémarrage) :**

- **Méthode :** `GET`
- **URL :** `{baseUrl}/project-decisions`
- **Réponse :** status `200`, body = tableau JSON des décisions, ex. :
```json
[
  { "action": "accept", "row_number": 5, "name": "...", "email": "...", "type_projet": "...", "createdAt": "2026-02-12T..." },
  { "action": "reject", "row_number": 3, "name": "...", "email": "...", "type_projet": "...", "createdAt": "2026-02-12T..." }
]
```
L’app Flutter utilise ce tableau (tri par `createdAt` décroissant, dernière décision par `row_number`) pour afficher les bons statuts au chargement.

---

## 2. Schéma Mongoose

Crée le fichier **`src/project-decisions/schemas/project-decision.schema.ts`** :

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ProjectDecisionDocument = ProjectDecision & Document;

@Schema({ timestamps: true, collection: 'project_decisions' })
export class ProjectDecision {
  @Prop({ required: true, enum: ['accept', 'reject'] })
  action: string;

  @Prop({ required: true })
  row_number: number;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  email: string;

  @Prop({ required: true })
  type_projet: string;

  @Prop({ default: null })
  budget_estime?: number;

  @Prop({ default: null })
  periode?: string;

  @Prop({ default: Date.now })
  createdAt: Date;
}

export const ProjectDecisionSchema = SchemaFactory.createForClass(ProjectDecision);
```

---

## 3. DTO

Crée **`src/project-decisions/dto/create-project-decision.dto.ts`** :

```typescript
import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateProjectDecisionDto {
  @IsIn(['accept', 'reject'])
  action: string;

  @IsInt()
  @Min(1)
  row_number: number;

  @IsString()
  name: string;

  @IsString()
  email: string;

  @IsString()
  type_projet: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  budget_estime?: number;

  @IsOptional()
  @IsString()
  periode?: string;
}
```

---

## 4. Service

Crée **`src/project-decisions/project-decisions.service.ts`** :

```typescript
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ProjectDecision, ProjectDecisionDocument } from './schemas/project-decision.schema';
import { CreateProjectDecisionDto } from './dto/create-project-decision.dto';

@Injectable()
export class ProjectDecisionsService {
  constructor(
    @InjectModel(ProjectDecision.name)
    private projectDecisionModel: Model<ProjectDecisionDocument>,
  ) {}

  async create(dto: CreateProjectDecisionDto): Promise<ProjectDecisionDocument> {
    const doc = new this.projectDecisionModel({
      action: dto.action,
      row_number: dto.row_number,
      name: dto.name,
      email: dto.email,
      type_projet: dto.type_projet,
      budget_estime: dto.budget_estime,
      periode: dto.periode,
    });
    return doc.save();
  }

  /** Pour que Flutter récupère les décisions au chargement (ordre anti-chronologique). */
  async findAll(): Promise<ProjectDecisionDocument[]> {
    return this.projectDecisionModel.find().sort({ createdAt: -1 }).exec();
  }
}
```

---

## 5. Controller

Crée **`src/project-decisions/project-decisions.controller.ts`** :

```typescript
import { Body, Controller, Get, Post } from '@nestjs/common';
import { ProjectDecisionsService } from './project-decisions.service';
import { CreateProjectDecisionDto } from './dto/create-project-decision.dto';

@Controller('project-decisions')
export class ProjectDecisionsController {
  constructor(private readonly projectDecisionsService: ProjectDecisionsService) {}

  @Post()
  async create(@Body() dto: CreateProjectDecisionDto) {
    await this.projectDecisionsService.create(dto);
    return { ok: true };
  }

  @Get()
  async findAll() {
    return this.projectDecisionsService.findAll();
  }
}
```

---

## 6. Module

Crée **`src/project-decisions/project-decisions.module.ts`** :

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProjectDecision, ProjectDecisionSchema } from './schemas/project-decision.schema';
import { ProjectDecisionsService } from './project-decisions.service';
import { ProjectDecisionsController } from './project-decisions.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ProjectDecision.name, schema: ProjectDecisionSchema },
    ]),
  ],
  controllers: [ProjectDecisionsController],
  providers: [ProjectDecisionsService],
})
export class ProjectDecisionsModule {}
```

---

## 7. Enregistrer le module dans `AppModule`

Dans **`src/app.module.ts`** :

```typescript
import { ProjectDecisionsModule } from './project-decisions/project-decisions.module';

@Module({
  imports: [
    // ... ConfigModule, MongooseModule.forRoot(...), etc.
    ProjectDecisionsModule,
  ],
})
export class AppModule {}
```

---

## 8. Résumé

| Fichier | Rôle |
|--------|------|
| `schemas/project-decision.schema.ts` | Modèle Mongoose (action, row_number, name, email, type_projet, optionnel: budget_estime, periode, createdAt) |
| `dto/create-project-decision.dto.ts` | Validation du body POST |
| `project-decisions.service.ts` | Création du document en base |
| `project-decisions.controller.ts` | `POST /project-decisions` (créer), `GET /project-decisions` (récupérer pour Flutter) |
| `project-decisions.module.ts` | Module NestJS à importer dans `AppModule` |

Une fois ce module déployé sur ton backend (ex. Railway), l’app Flutter enverra les décisions à `POST {baseUrl}/project-decisions` et elles seront stockées dans la collection MongoDB `project_decisions`.
