# Challenges & Leaderboard - Backend Implementation

## ⚠️ Current Status
- **Frontend**: ✅ Fully implemented (ChallengesScreen + ChallengesService)
- **Backend**: ❌ Missing leaderboard endpoint
- **Result**: Leaderboard shows **mock data** instead of real users

---

## Solution: Add Leaderboard Endpoint

The frontend will automatically fetch real user data once you add this endpoint to your NestJS backend.

Also add a dynamic challenge catalog endpoint so challenge definitions are not static in frontend.

---

## 1️⃣ Update User Schema

Add these fields to `src/users/schemas/user.schema.ts`:

```typescript
// src/users/schemas/user.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class User extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop()
  avatarUrl?: string;

  @Prop({ default: false })
  isPremium: boolean;

  // ✨ NEW: Challenge system fields
  @Prop({ default: 0 })
  challengePoints: number;

  @Prop({ type: [String], default: [] })
  completedChallenges: string[];

  // ... other existing fields
}

export const UserSchema = SchemaFactory.createForClass(User);
```

---

## 2️⃣ Implement GetLeaderboard Endpoint

Add this controller method to `src/auth/auth.controller.ts` (or create `src/users/users.controller.ts`):

```typescript
// Option A: Add to existing auth controller
// src/auth/auth.controller.ts

import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { UsersService } from '../users/users.service';

@Controller('api')
export class AuthController {
  // ... existing methods (login, register, etc)

  // ✨ NEW: Get leaderboard (top users by challenge points)
  @Get('users/leaderboard')
  @UseGuards(JwtAuthGuard) // Optional: remove if you want public leaderboard
  async getLeaderboard() {
    return await this.usersService.find({})
      .select('id name email avatarUrl challengePoints completedChallenges isPremium')
      .sort({ challengePoints: -1 })
      .limit(100)
      .lean();
  }

  // ✨ NEW: Get current user's profile including challenge data
  @Get('users/current-profile')
  @UseGuards(JwtAuthGuard)
  async getCurrentProfile(@Request() req) {
    const user = await this.usersService.findById(req.user.id);
    return {
      id: user._id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      challengePoints: user.challengePoints || 0,
      completedChallenges: user.completedChallenges || [],
      isPremium: user.isPremium || false,
    };
  }

  // ✨ NEW: Complete a challenge (add points)
  @Post('users/complete-challenge')
  @UseGuards(JwtAuthGuard)
  async completeChallenge(@Request() req, @Body() body: { challengeId: string; points: number }) {
    const updated = await this.usersService.findByIdAndUpdate(req.user.id, {
      $inc: { challengePoints: body.points },
      $addToSet: { completedChallenges: body.challengeId },
    }, { new: true });
    
    return {
      challengePoints: updated.challengePoints,
      completedChallenges: updated.completedChallenges,
      success: true,
    };
  }
}
```

### Dynamic Challenge Catalog Endpoint (Required)

Add this endpoint to return the list of active challenges from backend:

```typescript
@Get('challenges/catalog')
@UseGuards(JwtAuthGuard)
async getChallengeCatalog() {
  return await this.challengesService.findActiveCatalog();
}
```

Expected item shape:

```json
{
  "id": "ch_voice_email",
  "title": "Voice Email Master",
  "description": "Send an email using voice commands",
  "longDescription": "...",
  "icon": "mic",
  "points": 100,
  "type": "voice_email",
  "color": "#6366F1",
  "steps": ["..."],
  "requiresVoice": true,
  "requiresPayment": false,
  "isActive": true,
  "order": 1
}
```

**Option B: Create dedicated UsersController**

```typescript
// src/users/users.controller.ts
import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { UsersService } from './users.service';

@Controller('api/users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  // Get all users with their challenge rankings
  @Get('leaderboard')
  async getLeaderboard() {
    return await this.usersService.findLeaderboard();
  }

  // Complete a challenge
  @Post('complete-challenge')
  async completeChallenge(@Request() req, @Body() body: { challengeId: string; points: number }) {
    return await this.usersService.completeChallenge(req.user.id, body.challengeId, body.points);
  }
}
```

---

## 3️⃣ Update UsersService

Add these methods to `src/users/users.service.ts`:

```typescript
// src/users/users.service.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from './schemas/user.schema';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<User>) {}

  // ✨ NEW: Get leaderboard (top 100 users by challenge points)
  async findLeaderboard() {
    return await this.userModel
      .find({})
      .select('id name email avatarUrl challengePoints completedChallenges isPremium')
      .sort({ challengePoints: -1 })
      .limit(100)
      .lean();
  }

  // ✨ NEW: Complete a challenge and add points
  async completeChallenge(userId: string, challengeId: string, points: number) {
    return await this.userModel.findByIdAndUpdate(
      userId,
      {
        $inc: { challengePoints: points },
        $addToSet: { completedChallenges: challengeId },
      },
      { new: true }
    );
  }

  // ✨ NEW: Get user's challenge data
  async getUserChallengeData(userId: string) {
    return await this.userModel.findById(userId).select('challengePoints completedChallenges isPremium');
  }

  // Existing methods...
  async findById(id: string): Promise<User> {
    return await this.userModel.findById(id);
  }

  async findByEmail(email: string): Promise<User> {
    return await this.userModel.findOne({ email });
  }

  async create(data: any): Promise<User> {
    return await this.userModel.create(data);
  }
}
```

---

## 4️⃣ Register Controller & Service in Module

Add to `src/auth/auth.module.ts` or `src/users/users.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User, UserSchema } from './schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
```

---

## 5️⃣ Expected Response Format

### GET `/api/users/leaderboard`

```json
[
  {
    "_id": "user_id_1",
    "id": "user_id_1",
    "name": "Ahmed Hassan",
    "email": "ahmed@example.com",
    "avatarUrl": "https://...",
    "challengePoints": 2450,
    "completedChallenges": ["ch_voice_email", "ch_social_share", ...],
    "isPremium": true
  },
  {
    "_id": "user_id_2",
    "id": "user_id_2",
    "name": "Fatima Al Mansouri",
    "email": "fatima@example.com",
    "avatarUrl": null,
    "challengePoints": 2100,
    "completedChallenges": ["ch_voice_email", "ch_social_share", ...],
    "isPremium": true
  }
  // ... more users sorted by challengePoints DESC
]
```

### POST `/api/users/complete-challenge`

**Request:**
```json
{
  "challengeId": "ch_voice_email",
  "points": 100
}
```

**Response:**
```json
{
  "challengePoints": 1350,
  "completedChallenges": ["ch_voice_email"],
  "success": true
}
```

---

## 🎯 Testing

### 1️⃣ Manual Test with cURL

```bash
# Get leaderboard
curl -X GET http://localhost:3000/api/users/leaderboard \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Complete a challenge
curl -X POST http://localhost:3000/api/users/complete-challenge \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"challengeId": "ch_voice_email", "points": 100}'
```

### 2️⃣ Flutter Will Auto-Detect

Once this endpoint exists:
1. Frontend calls `GET /users/leaderboard`
2. `ChallengesService.fetchLeaderboard()` parses the response
3. `ChallengesScreen` displays real users instead of mock data
4. ✅ Dynamic leaderboard is live!

### 3️⃣ Where Challenge Completion Is Stored

When a user completes a challenge, data is persisted in MongoDB on the `users` collection:

1. Frontend sends `POST /api/users/complete-challenge` with `challengeId` and `points`
2. Backend updates user document with:
   - `$inc: { challengePoints: points }`
   - `$addToSet: { completedChallenges: challengeId }`
3. Updated user data is saved in database
4. Frontend refreshes profile/leaderboard using:
   - `GET /auth/me` (or `GET /users/current-profile`)
   - `GET /api/users/leaderboard`
  - `GET /api/challenges/catalog`

Example MongoDB update used by backend:

```typescript
await this.userModel.findByIdAndUpdate(
  userId,
  {
    $inc: { challengePoints: points },
    $addToSet: { completedChallenges: challengeId },
  },
  { new: true }
);
```

---

## 📋 Checklist

- [ ] Add `challengePoints` & `completedChallenges` to User schema
- [ ] Add dynamic `GET /api/challenges/catalog` endpoint
- [ ] Create or update UsersController with leaderboard endpoint
- [ ] Implement `findLeaderboard()` & `completeChallenge()` in UsersService
- [ ] Register module in main app module
- [ ] Test endpoint returns 100 users sorted by points
- [ ] Deploy to Railway
- [ ] Flutter will automatically show real users

---

## 🚀 Next Steps

1. **Implement this backend code** (15 mins)
2. **Deploy to Railway** production
3. **Restart Flutter app** - leaderboard will show real users automatically
4. **Test challenge completion** - points should update in real-time

No changes needed to Flutter code!
