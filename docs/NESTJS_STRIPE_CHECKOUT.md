# Stripe Checkout (abonnements) – Backend NestJS

Ce document décrit **uniquement le backend** à implémenter pour que l’app Flutter puisse ouvrir **Stripe Checkout** après le choix **mensuel / annuel**.

## Rôles front / back

| Couche | Rôle |
|--------|------|
| **Flutter (déjà en place)** | Envoie `POST /billing/create-checkout-session` avec le **JWT** et `{ "plan": "monthly" \| "yearly" }`, puis ouvre l’URL `url` renvoyée (navigateur). |
| **Backend NestJS (à faire)** | Utilise la **clé secrète** Stripe (`sk_test_…` / `sk_live_…`) pour créer une `checkout.sessions` en mode `subscription`, et renvoie `{ "url": "https://checkout.stripe.com/..." }`. |

**Ne jamais** mettre la clé secrète (`sk_…`) ni les **clés restreintes** “trop puissantes” dans le dépôt Flutter : seule la **clé publique** (`pk_…`) peut servir côté client si tu utilises Stripe.js / Payment Element ; avec **Checkout hébergé** (comme ici), le Flutter n’a même pas besoin de `pk_…`.

---

## 1. Prérequis Stripe (Dashboard)

1. Mode **Test** pour le développement.
2. Créer **un produit** « Premium » avec **deux tarifs récurrents** :
   - un **mensuel** → noter l’ID `price_…`
   - un **annuel** → noter l’ID `price_…`
3. Idéalement **les deux prix** sur le **même** produit ; si tu as deux produits distincts, ça fonctionne aussi tant que chaque `price_…` est bien un abonnement récurrent.

Les IDs du type `prod_…` servent surtout à l’organisation dans le Dashboard ; pour Checkout, c’est surtout les **`price_…`** qui comptent.

---

## 2. Variables d’environnement (Railway / `.env`)

À ajouter sur le **service NestJS** (pas sur Flutter) :

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| `STRIPE_SECRET_KEY` | Oui | `sk_test_…` ou `sk_live_…` (compte Stripe). |
| `STRIPE_PRICE_MONTHLY` | Oui | ID `price_…` du tarif **mensuel**. |
| `STRIPE_PRICE_YEARLY` | Oui | ID `price_…` du tarif **annuel**. |
| `STRIPE_SUCCESS_URL` | Oui | URL de retour après paiement réussi (page web ou deep link). Peut inclure `?session_id={CHECKOUT_SESSION_ID}` (Stripe remplace la variable). |
| `STRIPE_CANCEL_URL` | Oui | URL si l’utilisateur annule le paiement. |

Exemple :

```env
STRIPE_SECRET_KEY=sk_test_xxxxxxxx
STRIPE_PRICE_MONTHLY=price_xxxxxxxx
STRIPE_PRICE_YEARLY=price_xxxxxxxx
STRIPE_SUCCESS_URL=https://backendagentai-production.up.railway.app/billing/success?session_id={CHECKOUT_SESSION_ID}
STRIPE_CANCEL_URL=https://backendagentai-production.up.railway.app/billing/cancel
```

Pour une app mobile pure, `SUCCESS_URL` / `CANCEL_URL` doivent être des URL HTTP(S) valides. Stripe Checkout n’accepte pas directement un schéma personnalisé comme `piagent:///subscription/success?plan=yearly`.

La meilleure solution sans `piagent` est d’utiliser un **Universal Link / App Link** sur ton domaine :

```env
STRIPE_SUCCESS_URL=https://ton-domaine.com/subscription/success?plan={PLAN}
STRIPE_CANCEL_URL=https://ton-domaine.com/subscription/cancel
```

Ensuite, configure ton application mobile pour reconnaître les liens associés à `https://ton-domaine.com`. Sur iOS, cela nécessite un fichier `apple-app-site-association` sur le domaine. Sur Android, cela nécessite un `assetlinks.json`.

Avec cette configuration, Stripe redirigera vers `https://ton-domaine.com/subscription/success?plan=yearly` et l’app pourra ouvrir directement cette route si le lien est associé à l’application.

Si tu n’as pas encore de domaine associé, tu peux aussi utiliser une page de redirection minimale sur ton domaine qui affiche un bouton « Retour à l’app » ou qui redirige via JavaScript vers un schéma personnalisé juste après le paiement. Mais le `success_url` envoyé à Stripe doit rester une URL HTTP(S) valide.

---

## 3. Contrat API (aligné sur l’app Flutter)

- **Méthode / chemin :** `POST /billing/create-checkout-session`  
  (défini côté Flutter dans `api_config.dart` → `stripeCreateCheckoutSessionPath`.)

- **Headers :**
  - `Authorization: Bearer <access_token>` (même JWT que le reste de ton API).
  - `Content-Type: application/json`

- **Body JSON :**

```json
{ "plan": "monthly" }
```

ou

```json
{ "plan": "yearly" }
```

- **Réponse succès (200 ou 201) :**

```json
{ "url": "https://checkout.stripe.com/c/pay/cs_test_..." }
```

- **Erreurs possibles :** 401 si JWT invalide ; 400 si `plan` inconnu ; 500 si Stripe échoue (ne pas exposer le détail Stripe au client en prod — logger côté serveur).

---

## 4. Dépendance npm

```bash
npm install stripe
```

---

## 5. Exemple d’implémentation NestJS

Adaptation libre (noms de modules, guard JWT, `ConfigService`) selon ton repo existant.

### 5.1 DTO

```typescript
// create-checkout.dto.ts
import { IsIn, IsString } from 'class-validator';

export class CreateCheckoutDto {
  @IsString()
  @IsIn(['monthly', 'yearly'])
  plan: 'monthly' | 'yearly';
}
```

### 5.2 Service

```typescript
// billing.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

@Injectable()
export class BillingService {
  private stripe: Stripe;

  constructor(private readonly config: ConfigService) {
    const key = this.config.get<string>('STRIPE_SECRET_KEY');
    if (!key) throw new Error('STRIPE_SECRET_KEY is required');
    // La version d’API peut être fixée explicitement ; sinon le SDK utilise sa version par défaut.
    this.stripe = new Stripe(key);
  }

  async createSubscriptionCheckoutSession(
    plan: 'monthly' | 'yearly',
    opts?: { customerEmail?: string; userId?: string },
  ): Promise<string> {
    const priceId =
      plan === 'yearly'
        ? this.config.get<string>('STRIPE_PRICE_YEARLY')
        : this.config.get<string>('STRIPE_PRICE_MONTHLY');

    if (!priceId) {
      throw new BadRequestException('Stripe price not configured for this plan');
    }

    const successUrl = this.config.get<string>('STRIPE_SUCCESS_URL');
    const cancelUrl = this.config.get<string>('STRIPE_CANCEL_URL');
    if (!successUrl || !cancelUrl) {
      throw new BadRequestException('STRIPE_SUCCESS_URL / STRIPE_CANCEL_URL required');
    }

    const session = await this.stripe.checkout.sessions.create({
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      customer_email: opts?.customerEmail,
      client_reference_id: opts?.userId,
    });

    if (!session.url) {
      throw new BadRequestException('Stripe did not return a checkout URL');
    }
    return session.url;
  }
}
```

### 5.3 Controller

```typescript
// billing.controller.ts
import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { BillingService } from './billing.service';
import { CreateCheckoutDto } from './create-checkout.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // selon ton projet

@Controller('billing')
export class BillingController {
  constructor(private readonly billing: BillingService) {}

  @UseGuards(JwtAuthGuard)
  @Post('create-checkout-session')
  async createCheckout(@Body() dto: CreateCheckoutDto, @Req() req: any) {
    const user = req.user; // selon ton payload JWT
    const url = await this.billing.createSubscriptionCheckoutSession(dto.plan, {
      customerEmail: user?.email,
      userId: user?.sub ?? user?.id,
    });
    return { url };
  }
}
```

### 5.4 Module

```typescript
// billing.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';

@Module({
  imports: [ConfigModule],
  controllers: [BillingController],
  providers: [BillingService],
})
export class BillingModule {}
```

Enregistrer `BillingModule` dans `AppModule`.

---

## 6. Webhooks (recommandé pour la production)

Le retour sur `success_url` ne suffit pas pour savoir qu’un abonnement est **toujours actif** (impayé, annulation, etc.).

1. Dashboard Stripe → **Developers → Webhooks** → ajouter un endpoint, ex. `POST https://backendagentai-production.up.railway.app/billing/stripe-webhook`.
2. Événements utiles : `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`, `invoice.payment_failed`.
3. Vérifier la signature avec le **signing secret** `whsec_…` (`stripe.webhooks.constructEvent`).
4. Mettre à jour ton utilisateur en base :
   - `isPremium` ou `subscriptionActive` = true
   - `stripeCustomerId` = id du client Stripe
   - `subscriptionStatus` = `active` / `past_due` / `canceled`
   - `subscriptionPlan` = `monthly` / `yearly`
   - `subscriptionCurrentPeriodEnd` = date de fin de période
   - éventuellement `stripeSubscriptionId`

   Cette mise à jour doit se faire quand Stripe envoie `checkout.session.completed` ou `customer.subscription.updated`.

   Exemple de logique :
   - `checkout.session.completed` : valider le paiement et activer le forfait
   - `invoice.payment_failed` : marquer le compte comme en échec de paiement
   - `customer.subscription.deleted` : désactiver le forfait

---

## 7. Vérification rapide

1. Déployer le backend avec les variables d’env.
2. Depuis l’app : se connecter → Abonnement → **Continuer**.
3. Tu dois voir une requête `POST .../billing/create-checkout-session` **200** et l’ouverture de la page Stripe.
4. Carte test : `4242 4242 4242 4242`, date future, CVC quelconque.

---

## 8. Référence code Flutter (déjà présent)

- Chemin API : `lib/core/config/api_config.dart` → `stripeCreateCheckoutSessionPath`
- Client HTTP : `lib/data/services/stripe_checkout_service.dart`
- UI : `lib/presentation/pages/subscription_page.dart` (bouton Continuer + `url_launcher`)

---

## 9. Conformité App Store (iOS)

Pour des **abonnements à du contenu numérique** utilisé **dans** l’app iOS, Apple impose souvent **In‑App Purchase**, pas un paiement Stripe intégré à l’app. Stripe Checkout dans le navigateur peut convenir selon le type d’offre ; à valider avec les guidelines Apple et ton juriste.
