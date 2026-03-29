# Uber / Taxi Smart Reservation – Backend NestJS (Railway)

Documentation detaillee du contrat backend/frontend:
- Voir `docs/NESTJS_MOBILITY_BACKEND_DETAILED.md`

## Remarque Produit (etat actuel)
- Mode actuel: integration **seulement Uber**.
- Bolt/Taxi meter restent en roadmap (phase future), non actifs en production pour l'instant.
- Aucune fake data en runtime: afficher uniquement les estimations/propositions live backend.

## Objectif
Ajouter un backend de reservation intelligente qui:
- calcule des estimations reelles via Uber,
- choisit le prix le moins cher,
- applique des outils avances (trafic, historique, confiance),
- demande toujours confirmation utilisateur avant reservation finale,
- supporte une regle quotidienne (exemple: chaque jour a 08:00, Centre Ville -> La Marsa).

Important: `08:00 Centre Ville -> La Marsa` est uniquement un exemple de template editable. L'utilisateur peut definir n'importe quelle heure, origine et destination.

## Exemple concret (template modifiable)
- Regle active: tous les jours a 08:00
- Trajet: Centre Ville -> La Marsa
- Le systeme lance une estimation automatique
- Le systeme envoie une proposition a l'utilisateur:
  - meilleur fournisseur,
  - fourchette de prix,
  - ETA,
  - niveau de confiance,
  - raisons (trafic, demande, historique)
- L'utilisateur confirme manuellement
- Ensuite seulement: creation de reservation via provider

## Architecture recommandee

### 1) API NestJS
Module: `MobilityModule`

Services:
- `MobilityQuotesService`: appelle l'adapter Uber (live)
- `MobilityPricingEngine`: normalise et classe les offres
- `MobilityAutomationService`: gere les regles quotidiennes
- `MobilityApprovalService`: workflow de confirmation user
- `MobilityBookingService`: soumet la reservation finale

### 2) Worker/Job Scheduler
- Utiliser `@nestjs/schedule`
- Job every minute qui detecte les regles dues (ou cron direct par regle)
- Si regle due: calcul d'estimation + creation proposition en attente confirmation

### 3) Stockage MongoDB
Collections:
- `mobility_rules`
- `mobility_quote_runs`
- `mobility_proposals`
- `mobility_bookings`
- `mobility_provider_tokens`

## Endpoints proposes

### POST /mobility/quotes/estimate
Body:
```json
{
  "from": "Centre Ville",
  "to": "La Marsa",
  "pickupAt": "2026-03-29T08:00:00.000Z",
  "preferences": {
    "cheapestFirst": true,
    "maxEtaMinutes": 15
  }
}
```

Response:
```json
{
  "best": {
    "provider": "uberx",
    "minPrice": 16.2,
    "maxPrice": 21.0,
    "etaMinutes": 5,
    "confidence": 0.91,
    "reasons": [
      "live uber quote",
      "best price among enabled uber products"
    ]
  },
  "options": [
    {
      "provider": "uberx",
      "minPrice": 16.2,
      "maxPrice": 21.0,
      "etaMinutes": 5,
      "confidence": 0.91
    },
    {
      "provider": "uberxl",
      "minPrice": 20.0,
      "maxPrice": 27.5,
      "etaMinutes": 6,
      "confidence": 0.86
    }
  ]
}
```

### POST /mobility/rules
Body:
```json
{
  "name": "Daily commute template",
  "from": "Centre Ville",
  "to": "La Marsa",
  "timezone": "Africa/Tunis",
  "cron": "0 8 * * *",
  "enabled": true,
  "requireUserApproval": true,
  "preferences": {
    "cheapestFirst": true,
    "maxEtaMinutes": 20
  }
}
```

Note: les valeurs ci-dessus sont un exemple. En production, elles viennent du choix utilisateur.

### GET /mobility/rules
Retourne les regles utilisateur

### PATCH /mobility/rules/:id
Active/desactive et met a jour la regle

### GET /mobility/proposals/pending
Retourne les propositions en attente de confirmation

### POST /mobility/proposals/:proposalId/confirm
Confirme et lance la reservation

### POST /mobility/proposals/:proposalId/reject
Refuse la proposition

### GET /mobility/bookings
Historique reservations

## Algo "cheapest + outils avances"

### Inputs
- API provider quote
- trafic temps reel
- historique local (meme zone/horaire)
- meteo (optionnel)
- fiabilite provider (timeouts, cancellations)

### Scoring
- `priceScore`: plus bas prix moyen
- `etaScore`: plus bas temps d'arrivee
- `confidenceScore`: qualite signal provider + coherence historique

Exemple score global:
- `global = 0.55*priceScore + 0.25*etaScore + 0.20*confidenceScore`

### Regles de securite
- Ne jamais auto-booker si `requireUserApproval = true`
- Timeout de proposition (ex: 5 min)
- Si prix varie > X% avant confirmation: regenere estimation

## Workflow quotidien a 08:00 (Railway)
1. Scheduler detecte regle due
2. Appel `MobilityQuotesService`
3. Classement + selection meilleur plan
4. Creation proposition `PENDING_USER_APPROVAL`
5. Push notification / in-app alert
6. User confirme
7. `MobilityBookingService` reserve via provider
8. Sauvegarde resultat `CONFIRMED` ou `FAILED`

Remarque: l'heure `08:00` est illustrative. Le scheduler doit executer chaque regle a son heure configuree par l'utilisateur.

## Railway Setup

### Variables d'environnement
```env
MONGODB_URI=mongodb+srv://...
JWT_SECRET=...

UBER_CLIENT_ID=...
UBER_CLIENT_SECRET=...
UBER_REDIRECT_URI=https://<service>.up.railway.app/mobility/oauth/uber/callback

BOLT_API_KEY=...
BOLT_API_SECRET=...

MAPS_API_KEY=...
TRAFFIC_API_KEY=...

MOBILITY_DEFAULT_TIMEZONE=Africa/Tunis
MOBILITY_PROPOSAL_TTL_MINUTES=5
```

### Deployment
- Service web NestJS
- MongoDB plugin/cluster
- Optional: Redis pour queues/rate-limit

### Observabilite
- Logs structurees par `ruleId`, `proposalId`, `bookingId`
- Alerting sur:
  - erreurs provider,
  - quote vide,
  - echec reservation,
  - latence elevee

## DTOs minimaux (NestJS)

### EstimateRideDto
```ts
export class EstimateRideDto {
  from: string;
  to: string;
  pickupAt: string;
  preferences?: {
    cheapestFirst?: boolean;
    maxEtaMinutes?: number;
  };
}
```

### CreateMobilityRuleDto
```ts
export class CreateMobilityRuleDto {
  name: string;
  from: string;
  to: string;
  timezone: string;
  cron: string;
  enabled: boolean;
  requireUserApproval: boolean;
  preferences?: {
    cheapestFirst?: boolean;
    maxEtaMinutes?: number;
  };
}
```

## Recommandation integration frontend
- Ecran Travel appelle `POST /mobility/quotes/estimate`
- Affiche meilleur prix + alternatives
- Bouton `Confirm` -> `POST /mobility/proposals/:id/confirm`
- Si regle quotidienne active: afficher badge `Daily 08:00` + etat `Awaiting your approval`

## Securite
- JWT obligatoire sur tous les endpoints mobility
- tokens providers chiffrés at-rest
- audit trail complet des confirmations utilisateur
- rate-limit par user

## Niveaux de maturite

### Phase 1 (rapide)
- estimation live Uber + regles + confirmation manuelle

### Phase 2
- stabilisation Uber live + traffic API

### Phase 3
- extension multi-provider (Bolt/Taxi) + optimisation predictive (ML) + personalization par habitudes utilisateur
