# Mobility Backend Detaillee (NestJS + Railway)

## Objectif
Ce document definit une implementation backend complete pour le module mobilite utilise par l'ecran Travel Flutter.

Il couvre:
- le contrat API exact attendu par le frontend actuel,
- les DTO et schemas Mongo conseilles,
- la logique d'estimation, proposition, confirmation et regles quotidiennes,
- les erreurs standardisees,
- la configuration Railway,
- une checklist de verification end-to-end.

Important:
- Le scenario "08:00 Centre Ville -> La Marsa" reste un exemple editable.
- Le backend doit accepter des donnees dynamiques (destination libre + coords GPS optionnelles).
- Mode produit actuel: integration provider **Uber uniquement** (single-provider).
- Bolt/Taxi sont des extensions futures.
- Aucune fake data en runtime: estimations et propositions doivent venir du backend live.

---

## Contrat Requis Par Le Frontend Flutter

Le frontend appelle actuellement ces endpoints:

1. `POST /mobility/quotes/estimate`
2. `GET /mobility/rules`
3. `POST /mobility/rules`
4. `PATCH /mobility/rules/:id`
5. `POST /mobility/proposals`
6. `GET /mobility/proposals/pending`
7. `POST /mobility/proposals/:id/confirm`
8. `POST /mobility/proposals/:id/reject`

Tous ces endpoints doivent etre proteges par JWT (`Authorization: Bearer <token>`).

---

## Endpoint 1: Estimate

### Route
`POST /mobility/quotes/estimate`

### Body attendu
```json
{
  "from": "Current location",
  "to": "La Marsa",
  "pickupAt": "2026-03-28T13:30:00.000Z",
  "preferences": {
    "cheapestFirst": true,
    "maxEtaMinutes": 20
  },
  "fromCoordinates": {
    "latitude": 36.81,
    "longitude": 10.18
  },
  "toCoordinates": {
    "latitude": 36.88,
    "longitude": 10.33
  }
}
```

Notes:
- `fromCoordinates` et `toCoordinates` sont optionnels.
- Si les coords sont absentes, resolver `from`/`to` via geocoding backend ou providers.

### Reponse conseillee
```json
{
  "best": {
    "provider": "uberx",
    "minPrice": 16.2,
    "maxPrice": 21.0,
    "etaMinutes": 5,
    "confidence": 0.91,
    "reasons": [
      "low traffic",
      "high provider availability"
    ]
  },
  "options": [
    {
      "provider": "uberx",
      "minPrice": 16.2,
      "maxPrice": 21.0,
      "etaMinutes": 5,
      "confidence": 0.91,
      "reasons": ["low traffic"]
    },
    {
      "provider": "uberxl",
      "minPrice": 20.0,
      "maxPrice": 27.5,
      "etaMinutes": 6,
      "confidence": 0.86,
      "reasons": ["larger vehicle option"]
    }
  ]
}
```

Compatibilite frontend:
- `best` peut etre absent, mais `options` doit idealement etre non vide.
- Champs attendus: `provider`, `minPrice`, `maxPrice`, `etaMinutes`, `confidence`, `reasons`.

---

## Endpoint 2: Rules List

### Route
`GET /mobility/rules`

### Reponses compatibles
Le frontend supporte deux formats:

Format A (recommande):
```json
[
  {
    "id": "rule_123",
    "name": "Daily commute template",
    "from": "Current location",
    "to": "La Marsa",
    "cron": "0 8 * * *",
    "enabled": true
  }
]
```

Format B:
```json
{
  "items": [
    {
      "id": "rule_123",
      "name": "Daily commute template",
      "from": "Current location",
      "to": "La Marsa",
      "cron": "0 8 * * *",
      "enabled": true
    }
  ]
}
```

---

## Endpoint 3: Create Rule

### Route
`POST /mobility/rules`

### Body attendu
```json
{
  "name": "Daily commute template",
  "from": "Current location",
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

### Reponse
Retourner l'objet regle cree avec `id` ou `_id`.

---

## Endpoint 4: Update Rule

### Route
`PATCH /mobility/rules/:id`

### Patch minimal recu depuis Flutter
```json
{
  "enabled": true,
  "to": "La Marsa",
  "cron": "0 8 * * *",
  "requireUserApproval": true
}
```

### Reponse
Retourner la regle mise a jour (avec `id` ou `_id`).

---

## Endpoint 5: Create Proposal

### Route
`POST /mobility/proposals`

### Body attendu
```json
{
  "from": "Current location",
  "to": "La Marsa",
  "pickupAt": "2026-03-28T13:30:00.000Z",
  "selectedProvider": "uberx",
  "selectedPrice": 16.2,
  "selectedEtaMinutes": 5,
  "fromCoordinates": {
    "latitude": 36.81,
    "longitude": 10.18
  },
  "toCoordinates": {
    "latitude": 36.88,
    "longitude": 10.33
  },
  "routeSnapshot": {
    "distanceKm": 12.4,
    "durationMin": 18.0
  }
}
```

### Reponse recommandee
```json
{
  "id": "proposal_abc",
  "from": "Current location",
  "to": "La Marsa",
  "status": "PENDING_USER_APPROVAL",
  "provider": "uberx"
}
```

Note importante frontend:
- Si vous retournez `404`, le frontend tente un fallback via `GET /mobility/proposals/pending`.
- Pour UX propre, preferer `201` + proposal creee.

---

## Endpoint 6: Pending Proposals

### Route
`GET /mobility/proposals/pending`

### Formats compatibles
Format A:
```json
[
  {
    "id": "proposal_abc",
    "from": "Current location",
    "to": "La Marsa",
    "status": "PENDING_USER_APPROVAL",
    "provider": "uberx"
  }
]
```

Format B:
```json
{
  "items": [
    {
      "id": "proposal_abc",
      "from": "Current location",
      "to": "La Marsa",
      "status": "PENDING_USER_APPROVAL",
      "provider": "uberx"
    }
  ]
}
```

---

## Endpoint 7: Confirm Proposal

### Route
`POST /mobility/proposals/:id/confirm`

### Reponse
Status `200` ou `201` + JSON objet.

Exemple:
```json
{
  "ok": true,
  "proposalId": "proposal_abc",
  "status": "CONFIRMED",
  "bookingId": "booking_xyz"
}
```

---

## Endpoint 8: Reject Proposal

### Route
`POST /mobility/proposals/:id/reject`

### Reponse
Acceptees cote frontend:
- `200` avec JSON,
- `201` avec JSON,
- `204` sans body.

---

## Erreurs Standardisees

Recommandation:
- garder un schema commun `{ code, message, details? }`,
- codes HTTP coherents,
- logs server riches avec correlation id.

Exemples:
- `401` -> `AUTH_REQUIRED`
- `403` -> `FORBIDDEN`
- `404` -> `PROPOSAL_NOT_FOUND`
- `422` -> `VALIDATION_ERROR`
- `429` -> `RATE_LIMITED`
- `503` -> `PROVIDER_UNAVAILABLE`

Exemple body erreur:
```json
{
  "code": "PROVIDER_UNAVAILABLE",
  "message": "No provider reachable",
  "details": {
    "provider": "uber"
  }
}
```

---

## DTO NestJS Recommandes

```ts
export class CoordsDto {
  latitude: number;
  longitude: number;
}

export class EstimateRideDto {
  from: string;
  to: string;
  pickupAt: string;
  preferences?: {
    cheapestFirst?: boolean;
    maxEtaMinutes?: number;
  };
  fromCoordinates?: CoordsDto;
  toCoordinates?: CoordsDto;
}

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

export class CreateProposalDto {
  from: string;
  to: string;
  pickupAt: string;
  selectedProvider: string;
  selectedPrice: number;
  selectedEtaMinutes: number;
  fromCoordinates?: CoordsDto;
  toCoordinates?: CoordsDto;
  routeSnapshot?: {
    distanceKm?: number;
    durationMin?: number;
  };
}
```

---

## Modeles Mongo Conseilles

### mobility_rules
- `_id`
- `userId`
- `name`
- `from`
- `to`
- `timezone`
- `cron`
- `enabled`
- `requireUserApproval`
- `preferences`
- `createdAt`
- `updatedAt`

Index:
- `{ userId: 1, enabled: 1 }`
- `{ userId: 1, name: 1 }`

### mobility_proposals
- `_id`
- `userId`
- `from`
- `to`
- `pickupAt`
- `selectedProvider`
- `selectedPrice`
- `selectedEtaMinutes`
- `fromCoordinates?`
- `toCoordinates?`
- `routeSnapshot?`
- `status` (`PENDING_USER_APPROVAL`, `CONFIRMED`, `REJECTED`, `FAILED`)
- `expiresAt`
- `createdAt`
- `updatedAt`

Index:
- `{ userId: 1, status: 1, createdAt: -1 }`
- TTL optionnel sur `expiresAt` pour proposals en attente.

### mobility_bookings
- `_id`
- `userId`
- `proposalId`
- `provider`
- `status`
- `providerBookingRef?`
- `priceFinal?`
- `etaFinal?`
- `createdAt`
- `updatedAt`

---

## Scheduler Quotidien

- Utiliser `@nestjs/schedule`.
- Process type:
  1. Charger regles actives duees.
  2. Lancer estimate Uber live.
  3. Creer proposal `PENDING_USER_APPROVAL`.
  4. Notifier utilisateur (in-app, push, email selon produit).
  5. Attendre confirmation manuelle.

Securite:
- pas d'auto-booking si `requireUserApproval=true`.
- invalider proposal si expiration depassee.

---

## Config Railway

Variables minimales:
```env
MONGODB_URI=mongodb+srv://...
JWT_SECRET=...

MOBILITY_DEFAULT_TIMEZONE=Africa/Tunis
MOBILITY_PROPOSAL_TTL_MINUTES=5
MOBILITY_RETRY_COUNT=2
MOBILITY_RETRY_DELAY_MS=1500

MAPS_API_KEY=...
TRAFFIC_API_KEY=...
UBER_CLIENT_ID=...
UBER_CLIENT_SECRET=...
```

Observabilite:
- logs structures avec `userId`, `ruleId`, `proposalId`, `bookingId`.
- metricas conseillees:
  - estimate_success_rate
  - provider_timeout_rate
  - proposal_confirm_rate
  - booking_failure_rate

---

## Checklist E2E (avec Flutter actuel)

1. Login mobile valide.
2. Travel: saisir destination + Trace route.
3. Backend retourne estimate 200/201 avec `options`.
4. Daily rule toggle ON -> `POST /mobility/rules` ou `PATCH /mobility/rules/:id`.
5. Open Uber:
   - `POST /mobility/proposals`
   - `POST /mobility/proposals/:id/confirm`
6. Si create proposal non disponible, verifier fallback `GET /mobility/proposals/pending`.
7. Verifier persistence Mongo (rules/proposals/bookings).

---

## Bonnes Pratiques De Compatibilite Frontend

- Toujours retourner du JSON objet/liste quand possible.
- Eviter les bodies vides sur endpoints principaux (sauf `204` reject).
- Garder `id` (ou `_id`) dans les ressources retournees.
- Preserver les noms de champs du frontend existant.
- En cas d'evolution API, versionner (`/v1/mobility/...`) pour eviter de casser l'app.

---

## Resume Implementation Rapide

1. Creer `MobilityModule` avec controller + service.
2. Brancher guard JWT sur toutes les routes mobility.
3. Implementer estimate Uber live (pas de mock/fallback fake) + scoring.
4. Implementer rules CRUD minimal.
5. Implementer proposals create/pending/confirm/reject.
6. Ajouter indexes Mongo + logs + metricas.
7. Verifier contrats exacts avec le Flutter Travel actuel.
