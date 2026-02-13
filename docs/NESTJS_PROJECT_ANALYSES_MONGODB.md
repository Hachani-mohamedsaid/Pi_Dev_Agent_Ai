# NestJS – Stocker les analyses OpenAI des projets dans MongoDB

Quand l'utilisateur clique sur **Analyse** pour un projet, l'app Flutter génère une analyse avec OpenAI et la sauvegarde dans MongoDB. Lors des prochaines ouvertures, l'analyse est chargée depuis MongoDB au lieu d'être régénérée.

---

## 1. Endpoints attendus par Flutter

**GET** `/project-analyses/:rowNumber`
- Récupère l'analyse pour un projet (si elle existe).
- Réponse succès (200) : `{ "analysis": { ... } }` ou `{ "analysis": null }` si pas d'analyse.
- Réponse 404 si le projet n'existe pas.

**POST** `/project-analyses`
- Sauvegarde une nouvelle analyse.
- Body JSON :
```json
{
  "row_number": 5,
  "analysis": {
    "tools": ["React", "TypeScript", "Node.js"],
    "technicalProposal": {
      "architecture": "...",
      "stack": "...",
      "security": "...",
      "performance": "...",
      "tests": "...",
      "deployment": "...",
      "monitoring": "..."
    },
    "howToWork": "...",
    "developmentSteps": [
      {"title": "Étape 1", "description": "..."}
    ],
    "recommendations": "..."
  }
}
```
- Réponse succès (200) : `{ "ok": true }`.

---

## 2. Schéma Mongoose

Crée **`src/project-analyses/schemas/project-analysis.schema.ts`** :

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ProjectAnalysisDocument = ProjectAnalysis & Document;

@Schema({ timestamps: true, collection: 'project_analyses' })
export class ProjectAnalysis {
  @Prop({ required: true, unique: true })
  row_number: number;

  @Prop({ type: Object, required: true })
  analysis: {
    tools: string[];
    technicalProposal: {
      architecture: string;
      stack: string;
      security: string;
      performance: string;
      tests: string;
      deployment: string;
      monitoring: string;
    };
    howToWork: string;
    developmentSteps: Array<{
      title: string;
      description: string;
    }>;
    recommendations: string;
  };

  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const ProjectAnalysisSchema = SchemaFactory.createForClass(ProjectAnalysis);
```

---

## 3. DTO

Crée **`src/project-analyses/dto/create-project-analysis.dto.ts`** :

```typescript
import { IsInt, IsObject, Min } from 'class-validator';

export class CreateProjectAnalysisDto {
  @IsInt()
  @Min(1)
  row_number: number;

  @IsObject()
  analysis: {
    tools: string[];
    technicalProposal: {
      architecture: string;
      stack: string;
      security: string;
      performance: string;
      tests: string;
      deployment: string;
      monitoring: string;
    };
    howToWork: string;
    developmentSteps: Array<{
      title: string;
      description: string;
    }>;
    recommendations: string;
  };
}
```

---

## 4. Service

Crée **`src/project-analyses/project-analyses.service.ts`** :

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ProjectAnalysis, ProjectAnalysisDocument } from './schemas/project-analysis.schema';
import { CreateProjectAnalysisDto } from './dto/create-project-analysis.dto';

@Injectable()
export class ProjectAnalysesService {
  constructor(
    @InjectModel(ProjectAnalysis.name)
    private projectAnalysisModel: Model<ProjectAnalysisDocument>,
  ) {}

  async findByRowNumber(rowNumber: number): Promise<ProjectAnalysisDocument | null> {
    return this.projectAnalysisModel.findOne({ row_number: rowNumber }).exec();
  }

  async createOrUpdate(dto: CreateProjectAnalysisDto): Promise<ProjectAnalysisDocument> {
    const existing = await this.projectAnalysisModel.findOne({ row_number: dto.row_number }).exec();
    
    if (existing) {
      existing.analysis = dto.analysis;
      existing.updatedAt = new Date();
      return existing.save();
    }
    
    const doc = new this.projectAnalysisModel({
      row_number: dto.row_number,
      analysis: dto.analysis,
    });
    return doc.save();
  }
}
```

---

## 5. Controller

Crée **`src/project-analyses/project-analyses.controller.ts`** :

```typescript
import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ProjectAnalysesService } from './project-analyses.service';
import { CreateProjectAnalysisDto } from './dto/create-project-analysis.dto';

@Controller('project-analyses')
export class ProjectAnalysesController {
  constructor(private readonly projectAnalysesService: ProjectAnalysesService) {}

  @Get(':rowNumber')
  async findByRowNumber(@Param('rowNumber', ParseIntPipe) rowNumber: number) {
    const analysis = await this.projectAnalysesService.findByRowNumber(rowNumber);
    return { analysis: analysis?.analysis || null };
  }

  @Post()
  async createOrUpdate(@Body() dto: CreateProjectAnalysisDto) {
    await this.projectAnalysesService.createOrUpdate(dto);
    return { ok: true };
  }
}
```

---

## 6. Module

Crée **`src/project-analyses/project-analyses.module.ts`** :

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProjectAnalysis, ProjectAnalysisSchema } from './schemas/project-analysis.schema';
import { ProjectAnalysesService } from './project-analyses.service';
import { ProjectAnalysesController } from './project-analyses.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ProjectAnalysis.name, schema: ProjectAnalysisSchema },
    ]),
  ],
  controllers: [ProjectAnalysesController],
  providers: [ProjectAnalysesService],
})
export class ProjectAnalysesModule {}
```

---

## 7. Enregistrer le module dans `AppModule`

Dans **`src/app.module.ts`** :

```typescript
import { ProjectAnalysesModule } from './project-analyses/project-analyses.module';

@Module({
  imports: [
    // ... ConfigModule, MongooseModule.forRoot(...), etc.
    ProjectAnalysesModule,
  ],
})
export class AppModule {}
```

---

## 8. Résumé

| Fichier | Rôle |
|--------|------|
| `schemas/project-analysis.schema.ts` | Modèle Mongoose (row_number unique, analysis object, createdAt, updatedAt) |
| `dto/create-project-analysis.dto.ts` | Validation du body POST |
| `project-analyses.service.ts` | `findByRowNumber()`, `createOrUpdate()` |
| `project-analyses.controller.ts` | `GET /project-analyses/:rowNumber`, `POST /project-analyses` |
| `project-analyses.module.ts` | Module NestJS à importer dans `AppModule` |

Une fois ce module déployé, l'app Flutter :
1. Vérifie si l'analyse existe en MongoDB (GET).
2. Si oui → l'affiche directement (pas d'appel OpenAI).
3. Si non → génère avec OpenAI, sauvegarde en MongoDB (POST), puis affiche.

L'analyse est donc persistée et toujours affichée sans régénération.
