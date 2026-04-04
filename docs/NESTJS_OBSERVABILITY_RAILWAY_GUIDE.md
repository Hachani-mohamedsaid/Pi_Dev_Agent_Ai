# Guide Backend NestJS - Observability Pro et Simple (Railway)

## Objectif

Ce document explique ce que l'equipe backend doit ajouter pour monitorer l'application de bout en bout (frontend + backend) avec un setup professionnel mais simple a operer:

- Prometheus (metrics)
- Grafana (dashboards)
- Loki (logs)
- Alertmanager (alertes email)
- Sentry Cloud (erreurs applicatives)
- x-request-id (correlation frontend/backend/logs)

## Decision architecture (recommandee)

Pour garder une stack robuste sans complexite inutile:

- Self-hosted sur Railway: Prometheus, Grafana, Loki, Alertmanager
- Cloud: Sentry (SaaS)

Pourquoi Sentry cloud:

- Integration NestJS rapide
- Alerting erreurs applicatives plus simple
- Pas besoin d'operer un Sentry self-hosted (tres lourd)

## Cible technique

- Backend: NestJS
- Runtime: Node.js LTS
- Logs: JSON structure
- Correlation: x-request-id sur chaque requete
- Metrics endpoint: GET /metrics (prom-client)
- Health endpoint: GET /health

---

## Etape 1 - Correlation ID obligatoire (x-request-id)

### But

Tracer une requete de bout en bout:

frontend -> api gateway/backend -> logs -> Loki -> Grafana -> alertes

### A ajouter dans backend NestJS

1. Middleware global qui:
- Lit le header x-request-id si present
- Sinon genere un UUID
- Le met dans req.requestId
- Le renvoie dans la reponse (header x-request-id)

2. Logger/interceptor qui injecte requestId dans tous les logs de requete.

3. Exception filter global qui log les erreurs avec requestId.

### Contrat backend attendu

- Chaque reponse HTTP doit contenir le header x-request-id
- Chaque log backend doit contenir requestId
- Les erreurs 4xx/5xx doivent contenir requestId dans le payload JSON

Exemple payload erreur:

{
  "statusCode": 500,
  "message": "Internal server error",
  "requestId": "f7f0f4aa-f01e-4f01-925d-66ab4f4f8488",
  "timestamp": "2026-04-03T10:22:00.000Z"
}

---

## Etape 2 - Logging structure (JSON) + envoi vers Loki

### But

Centraliser les logs applicatifs dans Loki et les requeter dans Grafana.

### Recommandation simple

Utiliser Pino + pino-loki:

- sortie JSON locale (stdout) pour debug Railway
- push direct vers Loki pour observabilite

### Champs minimaux a logger

- timestamp
- level
- message
- service (ex: api-backend)
- env (dev/staging/prod)
- requestId
- method
- path
- statusCode
- durationMs
- userId (si connu)

### Variables d'environnement backend (logs)

- APP_NAME=pi-dev-backend
- NODE_ENV=production
- LOG_LEVEL=info
- LOKI_URL=http://loki.railway.internal:3100
- LOKI_USER=...
- LOKI_PASSWORD=...

Si Loki est sans auth en reseau interne Railway, LOKI_USER/LOKI_PASSWORD peuvent etre vides.

---

## Etape 3 - Metrics Prometheus (/metrics)

### But

Mesurer performance et disponibilite backend.

### A instrumenter

1. Metrics Node.js standard:
- process_cpu_user_seconds_total
- process_resident_memory_bytes
- nodejs_eventloop_lag_seconds

2. Metrics HTTP custom:
- http_requests_total{method,route,status}
- http_request_duration_seconds_bucket{method,route,status}
- http_requests_in_flight

3. Metrics metier (optionnel mais recommande):
- advisor_analyze_requests_total
- advisor_analyze_failures_total
- external_n8n_latency_seconds

### Endpoints backend

- GET /metrics -> format Prometheus text
- GET /health -> JSON status applicatif

---

## Etape 4 - Prometheus + Alertmanager (Railway)

### Services a deployer

1. prometheus
2. alertmanager
3. loki
4. grafana

Chaque service doit avoir son volume persistent Railway pour conserver la configuration et les donnees.

### Prometheus scrape minimal

- target backend: api-backend:3000/metrics
- interval: 15s
- timeout: 10s

### Alert rules minimales

1. BackendDown
- condition: up == 0 pendant 2m

2. High5xxRate
- condition: taux 5xx > 2% sur 5m

3. HighLatencyP95
- condition: p95 > 1.2s sur 10m

4. NoTrafficAnomaly (optionnel)
- condition: chute brutale trafic selon contexte

### Alertmanager (email)

Canal de notification demande: email.

Configurer SMTP:

- SMTP_HOST
- SMTP_PORT
- SMTP_USER
- SMTP_PASSWORD
- ALERT_FROM_EMAIL
- ALERT_TO_EMAIL

---

## Etape 5 - Sentry backend (cloud)

### But

Capturer exceptions, stack traces, release, environment.

### A ajouter

1. Initialiser Sentry au demarrage NestJS
2. Hook global exception filter vers Sentry
3. Ajouter tags:
- service
- env
- requestId
- userId (si dispo)
4. Sampling:
- tracesSampleRate raisonnable (ex: 0.1 en prod)

### Variables d'environnement backend (Sentry)

- SENTRY_DSN=...
- SENTRY_ENVIRONMENT=production
- SENTRY_RELEASE=git-sha-ou-version

---

## Etape 6 - Frontend contract (a coordonner)

Le frontend doit envoyer x-request-id sur chaque requete API.

Si absent, le backend en genere un, mais pour la correlation complete il vaut mieux que le frontend le fixe.

Convention recommandee:

- Header: x-request-id
- Valeur: UUID v4
- Un ID par requete sortante

---

## Etape 7 - Dashboards Grafana minimaux

### Dashboard 1: API Overview

- Requetes/min
- Taux erreurs 4xx/5xx
- Latence p50/p95/p99
- Requetes in-flight

### Dashboard 2: Infrastructure

- CPU process
- Memory RSS
- Event loop lag
- Uptime

### Dashboard 3: Logs & Incidents

- Logs erreurs (level=error)
- Logs par requestId
- Top endpoints en erreur

---

## Etape 8 - Variables d'environnement backend (liste finale)

- NODE_ENV=production
- APP_NAME=pi-dev-backend
- PORT=3000
- LOG_LEVEL=info
- SENTRY_DSN=...
- SENTRY_ENVIRONMENT=production
- SENTRY_RELEASE=...
- LOKI_URL=http://loki.railway.internal:3100
- LOKI_USER=...
- LOKI_PASSWORD=...

Si auth backend existante:

- JWT_SECRET=...
- JWT_EXPIRES_IN=...
- MONGODB_URI=...

---

## Etape 9 - Definition of Done (backend)

Le ticket observability backend est termine si:

1. GET /health renvoie 200
2. GET /metrics renvoie metrics Prometheus
3. Tous les logs contiennent requestId
4. x-request-id est present dans toutes les reponses
5. Une erreur backend remonte dans Sentry avec requestId
6. Les logs apparaissent dans Loki (Grafana Explore)
7. Les dashboards Grafana affichent trafic + latence + erreurs
8. Une alerte de test est recu par email via Alertmanager

---

## Plan de livraison conseille (rapide et sur)

Sprint 1 (1-2 jours):

- x-request-id
- logs JSON
- /health
- /metrics

Sprint 2 (1-2 jours):

- Loki + Grafana
- dashboards minimaux

Sprint 3 (1 jour):

- Alertmanager email
- Sentry cloud
- test incident end-to-end

---

## Notes Railway importantes

- Railway est tres pratique pour hoster Grafana/Loki/Prometheus/Alertmanager, mais verifier la persistence des volumes et la topologie reseau interne.
- Proteger Grafana avec auth forte.
- Restreindre acces public de Prometheus et Alertmanager (idealement interne uniquement).
- Toujours versionner les fichiers de config observability dans un repo infra ou dossier ops.

---

## Message a transmettre a l'equipe backend

"Merci d'implementer l'observability NestJS avec correlation x-request-id, metrics Prometheus (/metrics), logs JSON vers Loki, alertes email via Alertmanager, et erreurs vers Sentry cloud. La cible est un monitoring exploitable en production sur Railway avec dashboards Grafana (latence, erreurs, debit, ressources) et trace d'incident par requestId." 