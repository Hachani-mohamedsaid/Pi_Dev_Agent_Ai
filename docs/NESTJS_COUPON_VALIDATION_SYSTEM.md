# NestJS Backend - Coupon Validation System

## Objectif
Implémenter un système complet de validation de coupons pour les récompenses mensuelles et les upgrades de souscription. Le système doit:
- Valider les coupons avant le checkout (vérifier validité, propriétaire, expiration)
- Marquer les coupons comme utilisés après paiement réussi
- Générer des coupons pour le champion mensuel
- Envoyer des emails de confirmation

---

## 1) Schéma MongoDB - Collection `reward_coupons`

```typescript
// src/schemas/reward-coupon.schema.ts
import { Schema, Prop, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class RewardCoupon extends Document {
  @Prop({ required: true, unique: true, index: true })
  code: string; // Format: CHAMP-2026-04-ABC123

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId: string; // Propriétaire du coupon

  @Prop({ required: true, default: 30 })
  discountPercent: number; // Pourcentage de réduction (30%)

  @Prop({ 
    enum: ['monthly_champion', 'referral', 'test'], 
    default: 'monthly_champion' 
  })
  reason: string; // Raison de la génération

  @Prop({ required: true }) // Format: "2026-04" pour avril 2026
  month: string;

  @Prop({ default: false })
  used: boolean; // Marquer comme utilisé après consommation

  @Prop()
  usedAt: Date; // Date de consommation

  @Prop({ required: true, index: true })
  expiresAt: Date; // Date d'expiration du coupon

  @Prop({ required: false })
  planType?: string; // 'monthly' | 'yearly' | null (null = tous les plans)

  @Prop({ default: 1 })
  maxUses: number; // Nombre d'utilisations max (actuellement 1)

  @Prop()
  metadata?: Record<string, any>; // Données additionnelles

  createdAt?: Date;
  updatedAt?: Date;
}

export const RewardCouponSchema = SchemaFactory.createForClass(RewardCoupon);
RewardCouponSchema.index({ code: 1, userId: 1 });
RewardCouponSchema.index({ userId: 1, used: 1, expiresAt: 1 });
```

---

## 2) Endpoint Validation - `POST /coupons/validate`

### Logique
Valider un coupon avant le checkout Stripe sans le consommer.

### Contrôleur

```typescript
// src/coupons/coupons.controller.ts
import { 
  Controller, 
  Post, 
  Body, 
  UseGuards, 
  Request, 
  BadRequestException,
  ForbiddenException,
  HttpStatus
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CouponsService } from './coupons.service';

@Controller('coupons')
export class CouponsController {
  constructor(private couponsService: CouponsService) {}

  @Post('validate')
  @UseGuards(JwtAuthGuard)
  async validateCoupon(
    @Request() req,
    @Body() body: { couponCode: string; plan?: string }
  ) {
    const userId = req.user.id;
    const { couponCode, plan } = body;

    return this.couponsService.validateCoupon(couponCode, userId, plan);
  }
}
```

### Service

```typescript
// src/coupons/coupons.service.ts
import { Injectable, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { RewardCoupon } from './schemas/reward-coupon.schema';

@Injectable()
export class CouponsService {
  constructor(
    @InjectModel('RewardCoupon') private couponModel: Model<RewardCoupon>
  ) {}

  async validateCoupon(
    couponCode: string,
    userId: string,
    plan?: string
  ): Promise<{
    valid: boolean;
    active: boolean;
    discountPercent?: number;
    message?: string;
  }> {
    try {
      // 1) Trouver le coupon
      const coupon = await this.couponModel.findOne({ code: couponCode });

      if (!coupon) {
        return {
          valid: false,
          active: false,
          message: 'Coupon not found',
        };
      }

      // 2) Vérifier propriétaire
      if (coupon.userId.toString() !== userId) {
        return {
          valid: false,
          active: false,
          message: 'Coupon does not belong to you',
        };
      }

      // 3) Vérifier déjà utilisé
      if (coupon.used) {
        return {
          valid: false,
          active: false,
          message: 'Coupon already used',
        };
      }

      // 4) Vérifier expiration
      const now = new Date();
      if (now > coupon.expiresAt) {
        return {
          valid: false,
          active: false,
          message: 'Coupon expired',
        };
      }

      // 5) Vérifier plan compatibilité (optionnel)
      if (coupon.planType && plan && coupon.planType !== plan) {
        return {
          valid: false,
          active: true, // Coupon est valide, juste pas pour ce plan
          message: `Coupon not valid for ${plan} plan`,
        };
      }

      // 6) Coupon valide et actif
      return {
        valid: true,
        active: true,
        discountPercent: coupon.discountPercent,
        message: 'Coupon valid',
      };
    } catch (error) {
      console.error('Coupon validation error:', error);
      return {
        valid: false,
        active: false,
        message: 'Validation error',
      };
    }
  }

  // Marquer un coupon comme utilisé (après paiement Stripe réussi)
  async consumeCoupon(
    couponCode: string,
    userId: string
  ): Promise<RewardCoupon> {
    const coupon = await this.couponModel.findOneAndUpdate(
      {
        code: couponCode,
        userId: userId,
        used: false, // S'assurer qu'il n'est pas déjà utilisé
      },
      {
        $set: {
          used: true,
          usedAt: new Date(),
        },
      },
      { new: true }
    );

    if (!coupon) {
      throw new BadRequestException('Cannot consume coupon');
    }

    return coupon;
  }

  // Générer un coupon pour le champion mensuel
  async generateMonthlyChampionCoupon(
    userId: string,
    discountPercent: number = 30,
    month: string
  ): Promise<RewardCoupon> {
    // Format: CHAMP-YYYY-MM-XXXXX
    const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
    const code = `CHAMP-${month}-${randomSuffix}`;

    // Expiration: dernier jour du mois
    const [year, monthNum] = month.split('-');
    const expiresAt = new Date(
      parseInt(year),
      parseInt(monthNum),
      0,
      23,
      59,
      59,
      999
    );

    const coupon = new this.couponModel({
      code,
      userId,
      discountPercent,
      reason: 'monthly_champion',
      month,
      used: false,
      expiresAt,
    });

    return coupon.save();
  }
}
```

---

## 3) Endpoint Consommation - `POST /coupons/consume`

Appelé après un paiement Stripe réussi (via webhook ou après redirection checkout).

```typescript
// Dans coupons.controller.ts
@Post('consume')
@UseGuards(JwtAuthGuard)
async consumeCoupon(
  @Request() req,
  @Body() body: { couponCode: string }
) {
  const userId = req.user.id;
  return this.couponsService.consumeCoupon(body.couponCode, userId);
}
```

---

## 4) Webhook Stripe - Payment Success

Intégrer avec le webhook Stripe pour consommer le coupon.

```typescript
// src/billing/billing.controller.ts
import { Controller, Post, Body, RawBodyRequest, Req } from '@nestjs/common';
import { Request } from 'express';
import Stripe from 'stripe';

@Controller('webhooks')
export class WebhooksController {
  constructor(
    private stripeService: StripeService,
    private couponsService: CouponsService,
    private usersService: UsersService
  ) {}

  @Post('stripe')
  async handleStripeWebhook(@RawBodyRequest() req: Request) {
    const signature = req.headers['stripe-signature'] as string;
    const rawBody = req.rawBody;

    let event: Stripe.Event;
    try {
      event = this.stripeService.constructEvent(rawBody, signature);
    } catch (error) {
      console.error('Webhook signature verification failed:', error.message);
      return { received: false };
    }

    // Gérer l'événement payment_intent.succeeded
    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;

      try {
        // Récupérer les métadonnées de la session
        const metadata = paymentIntent.metadata || {};
        const userId = metadata.userId;
        const couponCode = metadata.couponCode;

        // Consommer le coupon si utilisé
        if (couponCode && userId) {
          await this.couponsService.consumeCoupon(couponCode, userId);
        }

        // Mettre à jour l'utilisateur (isPremium, plan type)
        await this.usersService.updateSubscription(userId, metadata.plan);
      } catch (error) {
        console.error('Error processing payment success:', error);
      }
    }

    return { received: true };
  }
}
```

---

## 5) Tâche Cron - Génération Mensuelle de Coupons

Exécutée le 1er de chaque mois à 00:05 UTC.

```typescript
// src/coupons/coupons-monthly.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../users/schemas/user.schema';
import { CouponsService } from './coupons.service';

@Injectable()
export class CouponsMonthlyService {
  private readonly logger = new Logger(CouponsMonthlyService.name);

  constructor(
    @InjectModel('User') private userModel: Model<User>,
    private couponsService: CouponsService
  ) {}

  // Exécuter le 1er du mois à 00:05 UTC
  @Cron(CronExpression.EVERY_1ST_DAY_OF_MONTH_AT_MIDNIGHT)
  async generateMonthlyChampionCoupon() {
    this.logger.log('🏆 Starting monthly champion coupon generation...');

    try {
      // 1) Déterminer le mois précédent
      const now = new Date();
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const monthStr = lastMonth
        .toISOString()
        .slice(0, 7); // Format: "2026-03"

      // 2) Trouver le #1 du leaderboard du mois précédent
      // (Supposer que challengePoints augmente au fil du temps)
      const topUser = await this.userModel
        .findOne()
        .sort({ challengePoints: -1 })
        .exec();

      if (!topUser) {
        this.logger.warn('No users found for monthly champion');
        return;
      }

      // 3) Générer coupon
      const coupon = await this.couponsService.generateMonthlyChampionCoupon(
        topUser._id.toString(),
        30, // 30% discount
        monthStr
      );

      this.logger.log(
        `✅ Monthly champion coupon created: ${coupon.code} for user ${topUser._id}`
      );

      // 4) Envoyer email
      await this.sendMonthlyChampionEmail(topUser, coupon);

    } catch (error) {
      this.logger.error('Error in monthly champion coupon generation:', error);
    }
  }

  private async sendMonthlyChampionEmail(user: any, coupon: any) {
    // Implémentée dans section 6
    this.logger.log(`📧 Sending email to ${user.email}...`);
  }
}
```

Configure dans `app.module.ts`:

```typescript
import { ScheduleModule } from '@nestjs/schedule';
import { CouponsMonthlyService } from './coupons/coupons-monthly.cron';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    // ... autres imports
  ],
  providers: [CouponsMonthlyService],
})
export class AppModule {}
```

---

## 6) Service Email - Envoyer Coupon au Champion

```typescript
// src/email/email.service.ts
import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD,
      },
    });
  }

  async sendMonthlyChampionEmail(
    userEmail: string,
    userName: string,
    couponCode: string,
    discountPercent: number,
    expiresAt: Date
  ): Promise<void> {
    const expiresDate = expiresAt.toLocaleDateString('fr-FR');

    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6;">
          <div style="max-width: 600px; margin: 0 auto;">
            <h1 style="color: #FFD700; text-align: center;">🏆 Félicitations!</h1>
            
            <p>Cher(e) ${userName},</p>
            
            <p>
              Vous avez été sélectionné(e) comme <strong>Champion du Mois</strong> 
              pour vos excellentes performances sur notre plateforme!
            </p>
            
            <p>En reconnaissance de votre engagement, nous vous offrons:</p>
            
            <div style="background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%); 
                        padding: 20px; 
                        border-radius: 8px; 
                        text-align: center;
                        margin: 20px 0;">
              <p style="color: white; font-size: 18px; margin: 0;">
                <strong>${discountPercent}% de réduction</strong>
              </p>
              <p style="color: white; font-size: 14px; font-style: italic; margin: 5px 0;">
                sur un upgrade premium
              </p>
            </div>
            
            <p><strong>Votre code coupon unique:</strong></p>
            <div style="background: #f0f0f0; 
                        padding: 15px; 
                        border-radius: 5px; 
                        text-align: center;
                        font-family: 'Courier New', monospace;
                        font-size: 24px;
                        font-weight: bold;
                        color: #333;">
              ${couponCode}
            </div>
            
            <p style="color: #888; font-size: 12px;">
              Ce code est valable jusqu'au <strong>${expiresDate}</strong> et utilisable une seule fois.
            </p>
            
            <a href="https://your-app.com/upgrade" 
               style="display: inline-block;
                      background: linear-gradient(135deg, #00BCD4 0%, #0097A7 100%);
                      color: white;
                      padding: 12px 30px;
                      border-radius: 5px;
                      text-decoration: none;
                      font-weight: bold;
                      margin-top: 20px;">
              Utiliser mon coupon
            </a>
            
            <p style="margin-top: 40px; color: #888; font-size: 12px;
                      border-top: 1px solid #ddd; padding-top: 20px;">
              Merci pour votre fidélité et votre engagement!<br>
              L'équipe AVA
            </p>
          </div>
        </body>
      </html>
    `;

    await this.transporter.sendMail({
      from: process.env.SMTP_FROM_EMAIL,
      to: userEmail,
      subject: `🏆 Vous êtes champion! Coupon ${discountPercent}% offert`,
      html: htmlContent,
    });
  }
}
```

---

## 7) Configuration Environment (.env)

```bash
# MongoDB
MONGODB_URI=mongodb://localhost:27017/pi-dev-agent

# SMTP
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@ava.ai

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_test_...

# App
APP_URL=https://your-app.com
```

---

## 8) Module Configuration

```typescript
// src/coupons/coupons.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CouponsController } from './coupons.controller';
import { CouponsService } from './coupons.service';
import { CouponsMonthlyService } from './coupons-monthly.cron';
import { RewardCouponSchema } from './schemas/reward-coupon.schema';
import { EmailModule } from '../email/email.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'RewardCoupon', schema: RewardCouponSchema },
    ]),
    EmailModule,
  ],
  controllers: [CouponsController],
  providers: [CouponsService, CouponsMonthlyService],
  exports: [CouponsService],
})
export class CouponsModule {}
```

---

## 9) Tests - cURL Commands

### 9.1) Créer un test coupon (directement en DB ou via admin endpoint)

```bash
# Option 1: Insérer directement en MongoDB
mongosh
db.reward_coupons.insertOne({
  code: "TEST-MNFBKHZO",
  userId: ObjectId("<your-user-id>"),
  discountPercent: 50,
  reason: "test",
  month: "2026-04",
  used: false,
  usedAt: null,
  expiresAt: ISODate("2026-04-30T23:59:59.000Z"),
  createdAt: new Date(),
  updatedAt: new Date()
})
```

### 9.2) Valider le coupon

```bash
curl -X POST http://localhost:3000/coupons/validate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "couponCode": "TEST-MNFBKHZO",
    "plan": "yearly"
  }'

# Réponse attendue:
{
  "valid": true,
  "active": true,
  "discountPercent": 50,
  "message": "Coupon valid"
}
```

### 9.3) Consommer un coupon (après paiement réussi)

```bash
curl -X POST http://localhost:3000/coupons/consume \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"couponCode": "TEST-MNFBKHZO"}'

# Réponse: coupon marqué comme used: true
```

### 9.4) Vérifier que le coupon est maintenant utilisé

```bash
curl -X POST http://localhost:3000/coupons/validate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"couponCode": "TEST-MNFBKHZO"}'

# Réponse:
{
  "valid": false,
  "active": false,
  "message": "Coupon already used"
}
```

---

## 10) Checklist Implémentation Backend

- [ ] Schéma MongoDB `reward_coupons` créé et indéxé
- [ ] CouponsService implémenté avec `validateCoupon()` et `consumeCoupon()`
- [ ] CouponsController avec endpoint `POST /coupons/validate`
- [ ] Consommation via endpoint `POST /coupons/consume`
- [ ] Webhook Stripe intégré pour consommer
- [ ] Tâche cron mensuelle configurée (génération du 1er du mois)
- [ ] Service email configuré et testé
- [ ] Variables d'environnement (.env) complétées
- [ ] Tests cURL valident le flux complet
- [ ] Module Coupons enregistré dans AppModule

---

## 11) Flux Complet - Résumé End-to-End

1. **Jour 1-30 du mois**: Utilisateurs complètent des challenges
2. **Jour 1 du mois suivant à 00:05**: Cron identifie le champion (max `challengePoints`)
3. **Immédiatement après**: Génère coupon unique + envoie email
4. **Après réception de l'email**: Utilisateur entre le code dans l'app
5. **Clic "Apply" dans l'app**: Frontend appelle `POST /coupons/validate`
6. **Backend vérifie**: propriétaire ✓, non utilisé ✓, non expiré ✓
7. **Réponse positive**: App affiche réduction 30% et active le bouton "Continue"
8. **Clic "Continue"**: App envoie couponCode à Stripe checkout
9. **Paiement réussi**: Webhook Stripe reçoit `payment_intent.succeeded`
10. **Webhook consomme**: Appelle `POST /coupons/consume` avec le coupon
11. **Marqué `used: true`**: Coupon ne peut plus être utilisé
12. **Confirmation**: Email de remerciement (optionnel)

---

## Notes Importantes

- **Sécurité**: Tous les endpoints `/coupons/*` doivent être protégés par `JwtAuthGuard`
- **Race conditions**: Utiliser MongoDB transactions pour consumeCoupon() si plusieurs requêtes simultanées
- **Timezone**: Toutes les dates en UTC (expiresAt, usedAt, createdAt)
- **Validations frontend + backend**: Le frontend valide (UX), le backend valide (sécurité)
- **Métadonnées Stripe**: Passer `couponCode` et `userId` dans `metadata` de la session Stripe

