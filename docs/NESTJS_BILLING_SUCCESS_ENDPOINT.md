# GET /billing/success — Endpoint de redirection Stripe

## 🎯 Objectif
Cet endpoint reçoit la redirection de Stripe après un paiement réussi, puis redirige l'utilisateur vers l'app mobile via **deep link**.

## 🔄 Flow

```
1. Utilisateur paie sur Stripe
2. Stripe redirige vers: GET https://backendagentai-production.up.railway.app/billing/success?session_id=cs_...&plan=monthly
3. Backend vérifie la session avec Stripe
4. Backend redirige vers: piagent://billing/success?plan=monthly (deep link)
5. App reçoit le deep link et affiche la page de succès
```

## 📋 Variables d'environnement requises

Dans **Railway** → **Backend Service** → **Variables** :
```
STRIPE_SECRET_KEY=sk_test_... ou sk_live_...
STRIPE_SUCCESS_REDIRECT_SCHEME=piagent://
```

## 💻 Code NestJS à ajouter

### 1. Créer le fichier `src/billing/billing.controller.ts`

Important: sur iOS/Safari, une redirection HTTP 302 vers un schéma custom (`piagent://`) peut être bloquée sans interaction utilisateur. Utilise une page HTML de pont avec bouton "Ouvrir l'app".

```typescript
import {
  Controller,
  Get,
  Query,
  BadRequestException,
  Inject,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Response } from 'express';
import Stripe from 'stripe';

@Controller('billing')
export class BillingController {
  private stripe: Stripe;
  private successRedirectScheme: string;

  constructor(@Inject(ConfigService) private configService: ConfigService) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not defined');
    }
    this.stripe = new Stripe(secretKey);
    this.successRedirectScheme =
      this.configService.get<string>('STRIPE_SUCCESS_REDIRECT_SCHEME') ||
      'piagent://';
  }

  /**
   * GET /billing/success
   * Reçoit la redirection de Stripe après paiement réussi
   * Ouvre une page HTML de pont qui déclenche le deep link
   */
  @Get('success')
  async handleStripeSuccess(
    @Res() res: Response,
    @Query('session_id') sessionId?: string,
    @Query('plan') plan?: string,
  ) {
    // Si session_id n'est pas fourni, on utilise le plan en paramètre
    if (!plan) {
      throw new BadRequestException('Missing plan parameter');
    }

    // Vérifier la session Stripe (optionnel mais recommandé)
    if (sessionId) {
      try {
        const session = await this.stripe.checkout.sessions.retrieve(sessionId);
        if (session.payment_status !== 'paid') {
          throw new Error('Payment not completed');
        }
      } catch (error) {
        // Si vérification échoue, on continue quand même avec le plan
        console.error('Failed to verify Stripe session:', error);
      }
    }

    const deepLinkUrl = `${this.successRedirectScheme}billing/success?plan=${encodeURIComponent(plan)}`;

    // Page de pont: déclenche tentative auto + bouton manuel (fiable iOS Safari).
    const html = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Retour à l'application</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 24px; background: #0f172a; color: #e2e8f0; }
      .card { max-width: 520px; margin: 8vh auto 0; background: #111827; border: 1px solid #334155; border-radius: 14px; padding: 20px; }
      h1 { margin: 0 0 8px; font-size: 22px; }
      p { color: #cbd5e1; line-height: 1.5; }
      a.btn { display: inline-block; margin-top: 14px; padding: 12px 16px; border-radius: 10px; text-decoration: none; background: #06b6d4; color: #06202b; font-weight: 700; }
      .sub { margin-top: 12px; font-size: 13px; color: #94a3b8; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>Paiement confirme</h1>
      <p>Appuie sur le bouton ci-dessous pour revenir dans l'application.</p>
      <a class="btn" href="${deepLinkUrl}">Ouvrir l'application</a>
      <p class="sub">Si rien ne se passe automatiquement, utilise le bouton.</p>
    </div>
    <script>
      setTimeout(function () { window.location.href = ${JSON.stringify(deepLinkUrl)}; }, 250);
    </script>
  </body>
</html>`;

    return res.status(200).type('html').send(html);
  }

  /**
   * GET /billing/cancel
   * Reçoit la redirection de Stripe après annulation
   */
  @Get('cancel')
  async handleStripeCancel(@Res() res: Response, @Query('plan') plan?: string) {
    const deepLinkUrl = `${this.successRedirectScheme}billing/cancel?plan=${encodeURIComponent(plan || 'unknown')}`;
    return res.redirect(deepLinkUrl);
  }
}
```

### 2. Mettre à jour `billing.service.ts`

Ajouter cette méthode pour créer la Checkout Session :

```typescript
async createCheckoutSession(userId: string, plan: 'monthly' | 'yearly') {
  const user = await this.userModel.findById(userId);
  if (!user || !user.email) {
    throw new BadRequestException('User not found or no email');
  }

  const priceId =
    plan === 'yearly'
      ? this.configService.get<string>('STRIPE_PRICE_YEARLY')
      : this.configService.get<string>('STRIPE_PRICE_MONTHLY');

  if (!priceId) {
    throw new Error(`STRIPE_PRICE_${plan.toUpperCase()} not configured`);
  }

  const successUrl = `${this.configService.get<string>('STRIPE_SUCCESS_URL')}?plan=${plan}`;
  const cancelUrl = this.configService.get<string>('STRIPE_CANCEL_URL');

  const session = await this.stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    customer_email: user.email,
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
    success_url: successUrl,
    cancel_url: cancelUrl,
  });

  return { url: session.url };
}
```

### 3. Importer le `BillingModule` dans `app.module.ts`

```typescript
import { BillingModule } from './billing/billing.module';

@Module({
  imports: [
    // ... autres imports
    BillingModule,
  ],
})
export class AppModule {}
```

## ⚙️ Configuration Stripe Dashboard

1. **Aller à** : Stripe Dashboard → **Developers** → **Webhooks**
2. **Ajouter endpoint** : `https://backendagentai-production.up.railway.app/billing/stripe-webhook`
3. **Événements à écouter** :
   - `checkout.session.completed`
   - `invoice.payment_failed`
   - `customer.subscription.deleted`
4. **Copier le secret** `whsec_...` et l'ajouter dans Railway comme `STRIPE_WEBHOOK_SECRET`

## 🔗 Deep Links reconnus par le frontend

L'app Flutter reconnaît automatiquement ces formats après redirection :
- ✅ `piagent://billing/success?plan=monthly`
- ✅ `https://...redirect.../billing/success?plan=monthly`
- ✅ `/billing/success?plan=monthly`

## 🧪 Test

### 1. Test local (développement Stripe)
```bash
# Depuis le terminal, tester avec curl:
curl "http://localhost:3000/billing/success?session_id=cs_test_...&plan=monthly"

# Réponse: redirection vers piagent://billing/success?plan=monthly
```

### 2. Test production
- Utiliser une vraie carte de test Stripe
- Vérifier que le deep link ouvre l'app
- Confirmer que la page de succès s'affiche

## 📝 Résumé des endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| `POST` | `/billing/create-checkout-session` | Créer une Stripe Checkout Session |
| `GET` | `/billing/success` | Redirection de succès Stripe → Deep link |
| `GET` | `/billing/cancel` | Redirection d'annulation Stripe → Deep link |
| `POST` | `/billing/stripe-webhook` | Webhook Stripe (créer/mettre à jour l'abonnement) |

## 🚀 Déployer sur Railway

1. Commit le code
2. Push vers `feature/mohamedSaid` (ou ta branche)
3. Railway redéploiera automatiquement
4. Test avec le formulaire de abonnement

---

**Notes** :
- Ne pas exposer `STRIPE_SECRET_KEY` au frontend
- Toujours vérifier `session.payment_status === 'paid'` côté serveur
- Le webhook doit mettre à jour `isPremium`, `subscriptionStatus`, etc. sur l'utilisateur

