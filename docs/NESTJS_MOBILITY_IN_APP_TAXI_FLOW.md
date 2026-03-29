# NestJS Backend - Mobility In-App Taxi Flow (No Web Redirect)

## Objectif
Cette specification definit le backend NestJS pour un parcours 100% in-app:
- l'utilisateur choisit A -> B dans Flutter,
- l'app demande une proposition,
- l'app confirme la demande,
- le backend suit la recherche chauffeur,
- l'app affiche en direct: en attente, accepte, refuse, annule.

Aucun deep link Uber/Web ne doit etre necessaire dans ce mode.

## Contexte Frontend Actuel
Le frontend Flutter (page Travel) attend deja:
- estimation live,
- creation de proposition,
- confirmation,
- rejet,
- lecture des propositions pending,
- lecture des bookings pour le statut final.

Routes consommees cote app:
1. POST /mobility/quotes/estimate
2. POST /mobility/proposals
3. POST /mobility/proposals/:id/confirm
4. POST /mobility/proposals/:id/reject
5. GET /mobility/proposals/pending
6. GET /mobility/bookings

Tous les endpoints sont JWT-protected.

## Regle Metier Critique
Ne pas renvoyer directement "ACCEPTED" quand l'utilisateur confirme.

Au moment du confirm, le backend doit passer par un etat intermediaire:
- PENDING_PROVIDER (ou SEARCHING_DRIVER)

Puis uniquement apres retour provider:
- ACCEPTED
ou
- REJECTED / FAILED / EXPIRED

## Machine a Etats Recommandee
Etats proposition/booking:
- PENDING_USER_APPROVAL
- PENDING_PROVIDER
- ACCEPTED
- REJECTED
- FAILED
- CANCELED
- EXPIRED
- COMPLETED

Transitions:
1. create proposal -> PENDING_USER_APPROVAL
2. confirm proposal -> PENDING_PROVIDER
3. provider callback success -> ACCEPTED
4. provider callback reject/timeout -> REJECTED ou EXPIRED
5. cancel from app -> CANCELED
6. end of trip -> COMPLETED

## Contrat API Recommande

### 1) POST /mobility/proposals
Body exemple:
```json
{
  "from": "Current location",
  "to": "La Marsa",
  "pickupAt": "2026-03-28T13:30:00.000Z",
  "selectedProvider": "uberx",
  "selectedPrice": 16.2,
  "selectedEtaMinutes": 5,
  "fromCoordinates": { "latitude": 36.80, "longitude": 10.18 },
  "toCoordinates": { "latitude": 36.86, "longitude": 10.31 },
  "routeSnapshot": { "distanceKm": 12.4, "durationMin": 18 }
}
```

Response 201:
```json
{
  "id": "prop_123",
  "from": "Current location",
  "to": "La Marsa",
  "status": "PENDING_USER_APPROVAL",
  "provider": "uberx"
}
```

### 2) POST /mobility/proposals/:id/confirm
Comportement:
- verrouiller la proposition,
- lancer la demande provider async,
- creer/mettre a jour booking en PENDING_PROVIDER.

Response 200/201:
```json
{
  "ok": true,
  "proposalId": "prop_123",
  "bookingId": "book_987",
  "status": "PENDING_PROVIDER",
  "message": "Driver search started"
}
```

### 3) POST /mobility/proposals/:id/reject
Comportement:
- annuler la proposition si encore annulable,
- passer statut CANCELED ou REJECTED selon regle interne.

Response possible:
- 200 with json
- 204 no content

### 4) GET /mobility/proposals/pending
Doit retourner les propositions non terminales (PENDING_USER_APPROVAL, PENDING_PROVIDER).

Response:
```json
[
  {
    "id": "prop_123",
    "from": "Current location",
    "to": "La Marsa",
    "status": "PENDING_PROVIDER",
    "provider": "uberx"
  }
]
```

### 5) GET /mobility/bookings
Doit permettre au frontend de retrouver le statut final relie a proposalId.

Response:
```json
[
  {
    "id": "book_987",
    "proposalId": "prop_123",
    "provider": "uberx",
    "status": "ACCEPTED"
  }
]
```

Format alternatif accepte:
```json
{
  "items": [
    {
      "id": "book_987",
      "proposalId": "prop_123",
      "provider": "uberx",
      "status": "ACCEPTED"
    }
  ]
}
```

## Webhooks Provider (obligatoire)
Le backend doit exposer un endpoint callback provider (ou worker polling provider API) pour mettre a jour booking/proposal.

Exemple:
- POST /mobility/providers/uber/webhook

Evenements minimum:
- DRIVER_ACCEPTED -> ACCEPTED
- DRIVER_NOT_FOUND ou TIMEOUT -> REJECTED/EXPIRED
- TRIP_FINISHED -> COMPLETED

## Mongo Schemas Conseilles

### mobility_proposals
- _id
- userId
- from
- to
- pickupAt
- selectedProvider
- selectedPrice
- selectedEtaMinutes
- status
- expiresAt
- createdAt
- updatedAt

Indexes:
- { userId: 1, status: 1, createdAt: -1 }
- { expiresAt: 1 } TTL optionnel

### mobility_bookings
- _id
- userId
- proposalId
- provider
- status
- providerBookingRef
- providerPayloadLast
- createdAt
- updatedAt

Indexes:
- { userId: 1, createdAt: -1 }
- { proposalId: 1 }

## Erreurs Standardisees
Format conseille:
```json
{
  "code": "PROVIDER_UNAVAILABLE",
  "message": "No driver available",
  "details": { "provider": "uber" }
}
```

Codes utiles:
- AUTH_REQUIRED (401)
- PROPOSAL_NOT_FOUND (404)
- PROPOSAL_EXPIRED (409)
- INVALID_STATE_TRANSITION (409)
- PROVIDER_TIMEOUT (504)
- PROVIDER_UNAVAILABLE (503)

## Pseudo-code Confirm (service NestJS)
```ts
async confirmProposal(id: string, userId: string) {
  const proposal = await this.proposalsRepo.findOwned(id, userId);
  if (!proposal) throw new NotFoundException('PROPOSAL_NOT_FOUND');

  if (proposal.status !== 'PENDING_USER_APPROVAL') {
    throw new ConflictException('INVALID_STATE_TRANSITION');
  }

  proposal.status = 'PENDING_PROVIDER';
  await this.proposalsRepo.save(proposal);

  const booking = await this.bookingsRepo.upsertByProposalId({
    proposalId: proposal.id,
    userId,
    provider: proposal.selectedProvider,
    status: 'PENDING_PROVIDER'
  });

  this.providerDispatchQueue.enqueue({ proposalId: proposal.id, bookingId: booking.id });

  return {
    ok: true,
    proposalId: proposal.id,
    bookingId: booking.id,
    status: 'PENDING_PROVIDER',
    message: 'Driver search started'
  };
}
```

## Checklist QA Backend
1. Confirm ne retourne jamais ACCEPTED immediatement sans callback provider.
2. GET /mobility/bookings retourne un item avec proposalId pour le polling frontend.
3. Cancel depuis app met bien CANCELED et stoppe la recherche provider.
4. Timeout provider met EXPIRED ou REJECTED.
5. Toutes les routes mobility sont JWT-protected.

## Tests cURL (production Railway)
```bash
BASE="https://backendagentai-production.up.railway.app"
TOKEN="<JWT>"

# Create proposal
curl -X POST "$BASE/mobility/proposals" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "from":"Current location",
    "to":"La Marsa",
    "pickupAt":"2026-03-28T13:30:00.000Z",
    "selectedProvider":"uberx",
    "selectedPrice":16.2,
    "selectedEtaMinutes":5
  }'

# Confirm proposal
curl -X POST "$BASE/mobility/proposals/<PROPOSAL_ID>/confirm" \
  -H "Authorization: Bearer $TOKEN"

# Fetch pending proposals
curl "$BASE/mobility/proposals/pending" \
  -H "Authorization: Bearer $TOKEN"

# Fetch bookings
curl "$BASE/mobility/bookings" \
  -H "Authorization: Bearer $TOKEN"

# Cancel request
curl -X POST "$BASE/mobility/proposals/<PROPOSAL_ID>/reject" \
  -H "Authorization: Bearer $TOKEN"
```

## Notes d'Implementation
- Eviter toute fake data en runtime.
- Logger userId, proposalId, bookingId sur chaque transition.
- Utiliser un job retry exponentiel pour appels provider.
- Ajouter un guard anti-double-confirmation (idempotency key ou verrou DB).

## Troubleshooting - Uber Invalid URL

Erreur vue en logs:
- Uber live quote failed: Invalid URL
- Invalid URL//api.uber.com/v1.2/estimates/price

Cause:
- La base URL Uber est vide ou mal normalisee,
- puis concatenee avec un path commencant par //,
- ce qui produit une URL invalide.

Exemples a eviter:
```ts
const url = `${process.env.UBER_BASE_URL}//api.uber.com/v1.2/estimates/price`;
// ou
const url = `${process.env.UBER_BASE_URL}/v1.2/estimates/price`; // si UBER_BASE_URL est vide
```

Fix recommande (robuste):
```ts
const uberBase = process.env.UBER_API_BASE_URL ?? 'https://api.uber.com';
const endpoint = new URL('/v1.2/estimates/price', uberBase);

endpoint.searchParams.set('start_latitude', String(startLat));
endpoint.searchParams.set('start_longitude', String(startLng));
endpoint.searchParams.set('end_latitude', String(endLat));
endpoint.searchParams.set('end_longitude', String(endLng));

const response = await this.httpService.axiosRef.get(endpoint.toString(), {
  headers: {
    Authorization: `Bearer ${accessToken}`,
  },
  timeout: 10000,
});
```

Validation config Railway:
```env
UBER_API_BASE_URL=https://api.uber.com
UBER_CLIENT_ID=...
UBER_CLIENT_SECRET=...
```

Check defensif au demarrage NestJS:
```ts
const raw = this.configService.get<string>('UBER_API_BASE_URL');
if (!raw) throw new Error('UBER_API_BASE_URL is not configured');
new URL(raw); // valide schema + host
```

Rappel:
- Utiliser toujours new URL(path, base) au lieu de concatener des strings.
- Path doit etre '/v1.2/estimates/price' (pas '//api.uber.com/...').
