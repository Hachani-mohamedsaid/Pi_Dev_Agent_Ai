# NestJS – Stocker les Goals (objectifs) dans MongoDB

L’app Flutter envoie les requêtes Goals avec le **JWT** (header `Authorization: Bearer <token>`). Ce document décrit comment ajouter le module **Goals** sur ton backend NestJS pour **persister les objectifs en MongoDB** et les associer à l’utilisateur connecté.

---

## 1. Endpoints attendus par Flutter

- **GET** `/goals` – Liste des objectifs de l’utilisateur connecté (JWT requis).
- **GET** `/goals/achievements` – Liste des achievements (réponse 200 + tableau JSON).
- **POST** `/goals` – Créer un objectif (body: title, category, deadline, dailyActions optionnel). JWT requis.
- **PATCH** `/goals/:id` – Mettre à jour (ex. progress). JWT requis.
- **PATCH** `/goals/:id/actions/:actionId` – Toggle action (body: completed). JWT requis.

Le backend doit **extraire l’userId du JWT** et ne retourner / modifier que les objectifs de cet utilisateur.

---

## 2. Schéma Mongoose

Crée **`src/goals/schemas/goal-action.schema.ts`** :

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

@Schema({ _id: false })
export class GoalAction {
  @Prop({ required: true })
  id: string;

  @Prop({ required: true })
  label: string;

  @Prop({ default: false })
  completed: boolean;
}

export const GoalActionSchema = SchemaFactory.createForClass(GoalAction);
```

Crée **`src/goals/schemas/goal.schema.ts`** :

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { GoalAction, GoalActionSchema } from './goal-action.schema';

export type GoalDocument = Goal & Document;

@Schema({ timestamps: true, collection: 'goals' })
export class Goal {
  @Prop({ required: true, index: true })
  userId: string;

  @Prop({ required: true })
  title: string;

  @Prop({ default: 'Personal' })
  category: string;

  @Prop({ default: 0, min: 0, max: 100 })
  progress: number;

  @Prop({ default: 'Ongoing' })
  deadline: string;

  @Prop({ type: [GoalActionSchema], default: [] })
  dailyActions: GoalAction[];

  @Prop({ default: 0 })
  streak: number;
}

export const GoalSchema = SchemaFactory.createForClass(Goal);
```

---

## 3. DTOs

Crée **`src/goals/dto/create-goal.dto.ts`** :

```typescript
import { IsString, IsOptional, IsArray, ValidateNested, IsNumber, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

class DailyActionDto {
  @IsString()
  id: string;

  @IsString()
  label: string;

  @IsBoolean()
  @IsOptional()
  completed?: boolean;
}

export class CreateGoalDto {
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  category?: string;

  @IsString()
  @IsOptional()
  deadline?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DailyActionDto)
  @IsOptional()
  dailyActions?: DailyActionDto[];
}
```

Crée **`src/goals/dto/update-goal-progress.dto.ts`** :

```typescript
import { IsInt, Min, Max } from 'class-validator';

export class UpdateGoalProgressDto {
  @IsInt()
  @Min(0)
  @Max(100)
  progress: number;
}
```

Crée **`src/goals/dto/toggle-action.dto.ts`** :

```typescript
import { IsBoolean } from 'class-validator';

export class ToggleActionDto {
  @IsBoolean()
  completed: boolean;
}
```

---

## 4. Service

Crée **`src/goals/goals.service.ts`** :

```typescript
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Goal, GoalDocument } from './schemas/goal.schema';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalProgressDto } from './dto/update-goal-progress.dto';
import { ToggleActionDto } from './dto/toggle-action.dto';

@Injectable()
export class GoalsService {
  constructor(
    @InjectModel(Goal.name)
    private goalModel: Model<GoalDocument>,
  ) {}

  async create(userId: string, dto: CreateGoalDto): Promise<GoalDocument> {
    const doc = new this.goalModel({
      userId,
      title: dto.title,
      category: dto.category ?? 'Personal',
      progress: 0,
      deadline: dto.deadline ?? 'Ongoing',
      dailyActions: dto.dailyActions ?? [],
      streak: 0,
    });
    return doc.save();
  }

  async findAllByUser(userId: string): Promise<GoalDocument[]> {
    return this.goalModel.find({ userId }).sort({ createdAt: -1 }).lean().exec();
  }

  async findOne(id: string, userId: string): Promise<GoalDocument> {
    const goal = await this.goalModel.findOne({ _id: id, userId }).exec();
    if (!goal) throw new NotFoundException('Goal not found');
    return goal;
  }

  async updateProgress(id: string, userId: string, dto: UpdateGoalProgressDto): Promise<GoalDocument> {
    const goal = await this.goalModel.findOneAndUpdate(
      { _id: id, userId },
      { $set: { progress: dto.progress } },
      { new: true },
    ).exec();
    if (!goal) throw new NotFoundException('Goal not found');
    return goal;
  }

  async toggleAction(
    goalId: string,
    actionId: string,
    userId: string,
    dto: ToggleActionDto,
  ): Promise<GoalDocument> {
    const goal = await this.goalModel.findOne({ _id: goalId, userId }).exec();
    if (!goal) throw new NotFoundException('Goal not found');
    const actions = goal.dailyActions.map((a) =>
      a.id === actionId ? { ...a.toObject(), completed: dto.completed } : a.toObject(),
    );
    goal.dailyActions = actions;
    return goal.save();
  }

  /** Achievements : à adapter selon ta logique (streaks, tâches complétées, etc.). */
  async getAchievements(userId: string): Promise<Array<{ id: string; icon: string; title: string; date: string }>> {
    const goals = await this.goalModel.find({ userId }).lean().exec();
    const achieved: Array<{ id: string; icon: string; title: string; date: string }> = [];
    goals.forEach((g, i) => {
      if (g.progress >= 100)
        achieved.push({ id: `ach_${g._id}`, icon: '🎯', title: 'Goal achieved', date: 'Last week' });
      if (g.streak >= 7)
        achieved.push({ id: `streak_${g._id}`, icon: '🏆', title: '7-day streak', date: 'Yesterday' });
    });
    return achieved.slice(0, 10);
  }
}
```

**Important :** Les objectifs sont créés avec `_id` (ObjectId). Flutter envoie parfois un `id` string (ex. `local_xxx`). Pour PATCH, le backend reçoit `:id` dans l’URL : si c’est un ObjectId valide, tu peux utiliser `findOne({ _id: id, userId })`. Si tu préfères un id string côté API, ajoute un champ `id: string` unique au schéma et utilise-le dans les routes.

---

## 5. Controller (avec JWT)

Tu dois avoir un **guard JWT** qui met `user` (ex. `user.sub` ou `user.id`) dans la requête. Exemple avec `@UseGuards(JwtAuthGuard)` et `req.user.sub` :

Crée **`src/goals/goals.controller.ts`** :

```typescript
import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { GoalsService } from './goals.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalProgressDto } from './dto/update-goal-progress.dto';
import { ToggleActionDto } from './dto/toggle-action.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // adapte le chemin selon ton projet

@Controller('goals')
@UseGuards(JwtAuthGuard)
export class GoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Get()
  async findAll(@Req() req: any) {
    const userId = req.user?.sub ?? req.user?.id;
    const goals = await this.goalsService.findAllByUser(userId);
    return goals.map((g) => ({
      id: g._id.toString(),
      title: g.title,
      category: g.category,
      progress: g.progress,
      deadline: g.deadline,
      dailyActions: g.dailyActions,
      streak: g.streak,
    }));
  }

  @Get('achievements')
  async getAchievements(@Req() req: any) {
    const userId = req.user?.sub ?? req.user?.id;
    return this.goalsService.getAchievements(userId);
  }

  @Post()
  async create(@Req() req: any, @Body() dto: CreateGoalDto) {
    const userId = req.user?.sub ?? req.user?.id;
    const goal = await this.goalsService.create(userId, dto);
    return {
      id: goal._id.toString(),
      title: goal.title,
      category: goal.category,
      progress: goal.progress,
      deadline: goal.deadline,
      dailyActions: goal.dailyActions,
      streak: goal.streak,
    };
  }

  @Patch(':id')
  async updateProgress(
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: UpdateGoalProgressDto,
  ) {
    const userId = req.user?.sub ?? req.user?.id;
    const goal = await this.goalsService.updateProgress(id, userId, dto);
    return {
      id: goal._id.toString(),
      title: goal.title,
      category: goal.category,
      progress: goal.progress,
      deadline: goal.deadline,
      dailyActions: goal.dailyActions,
      streak: goal.streak,
    };
  }

  @Patch(':id/actions/:actionId')
  async toggleAction(
    @Param('id') id: string,
    @Param('actionId') actionId: string,
    @Req() req: any,
    @Body() dto: ToggleActionDto,
  ) {
    const userId = req.user?.sub ?? req.user?.id;
    const goal = await this.goalsService.toggleAction(id, actionId, userId, dto);
    return {
      id: goal._id.toString(),
      title: goal.title,
      category: goal.category,
      progress: goal.progress,
      deadline: goal.deadline,
      dailyActions: goal.dailyActions,
      streak: goal.streak,
    };
  }
}
```

---

## 6. Module

Crée **`src/goals/goals.module.ts`** :

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Goal, GoalSchema } from './schemas/goal.schema';
import { GoalsService } from './goals.service';
import { GoalsController } from './goals.controller';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Goal.name, schema: GoalSchema }]),
  ],
  controllers: [GoalsController],
  providers: [GoalsService],
})
export class GoalsModule {}
```

---

## 7. Enregistrer dans `AppModule`

Dans **`src/app.module.ts`** :

```typescript
import { GoalsModule } from './goals/goals.module';

@Module({
  imports: [
    // ... ConfigModule, MongooseModule.forRoot(...), AuthModule, etc.
    GoalsModule,
  ],
})
export class AppModule {}
```

---

## 8. Résumé

| Fichier | Rôle |
|--------|------|
| `schemas/goal-action.schema.ts` | Sous-document action (id, label, completed) |
| `schemas/goal.schema.ts` | Document Goal (userId, title, category, progress, deadline, dailyActions, streak) |
| `dto/create-goal.dto.ts` | Validation POST body |
| `dto/update-goal-progress.dto.ts` | Validation PATCH body (progress) |
| `dto/toggle-action.dto.ts` | Validation PATCH body (completed) |
| `goals.service.ts` | CRUD + getAchievements, filtré par userId |
| `goals.controller.ts` | GET/POST/PATCH avec JwtAuthGuard, userId depuis req.user |
| `goals.module.ts` | Module à importer dans AppModule |

Une fois ce module déployé sur ton backend (ex. Railway), l’app Flutter enverra le **JWT** sur toutes les requêtes Goals. Le backend stockera et retournera uniquement les objectifs de l’utilisateur connecté.
