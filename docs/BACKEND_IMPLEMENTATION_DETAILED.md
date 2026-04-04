# 📚 Guide Détaillé: Ce Que Le Backend Doit Implémenter

## 🎯 Vue d'ensemble

Le **frontend** envoie déjà:
- ✅ `x-request-id` header (UUID unique par requête)
- ✅ `Content-Type: application/json` header
- ✅ `Authorization: Bearer <token>` (si authentifié)

Le **backend** doit:
1. 🔴 **Lire** le header `x-request-id` (ou générer si absent)
2. 📝 **Logger** avec ce request ID
3. 📊 **Collecter des métriques** (latence, erreurs, etc.)
4. 📤 **Envoyer** le request ID dans les réponses

---

## 📋 Étapes d'Implémentation (15 minutes)

### Étape 1: Installation des dépendances

```bash
cd backend/
npm install prom-client winston
```

**Pourquoi?**
- `prom-client` = Exporte les métriques dans format Prometheus
- `winston` = Logger professionnel avec champs structurés

---

### Étape 2: Créer le middleware Request ID

**Fichier:** `src/observability/request-id.middleware.ts`

```typescript
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

/**
 * Middleware: Extraire ou générer un Request ID unique
 * 
 * Ce que le frontend envoie:
 *   GET /api/goals
 *   Headers: {
 *     'x-request-id': '550e8400-e29b-41d4-a716-446655440000'  // UUID du frontend
 *   }
 * 
 * Ce que ce middleware fait:
 *   - Lit le header 'x-request-id'
 *   - Si absent, génère un nouveau UUID
 *   - Attache au objet req (req.requestId)
 *   - Ajoute au réponse (response header)
 */
@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    // 1. Extraire le request ID du frontend (ou générer un nouveau)
    const requestId = (req.headers['x-request-id'] as string) || uuidv4();
    
    // 2. L'attacher à l'objet request (accessible dans toute l'app)
    req['requestId'] = requestId;
    
    // 3. L'envoyer dans la réponse (le frontend peut vérifier que c'est le même)
    res.setHeader('x-request-id', requestId);
    res.setHeader('x-response-time', new Date().toISOString());
    
    // 4. Continuer
    next();
  }
}

/**
 * RÉSULTAT:
 * 
 * Frontend envoie:
 *   x-request-id: abc-123-def
 * 
 * Backend répond:
 *   x-request-id: abc-123-def  (echo)
 *   x-response-time: 2026-04-04T14:30:00.000Z
 * 
 * Logs backend affichent:
 *   "[abc-123-def] GET /api/goals - 200 (42ms)"
 */
```

---

### Étape 3: Créer le middleware Prometheus

**Fichier:** `src/observability/prometheus.middleware.ts`

```typescript
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as promClient from 'prom-client';

/**
 * MÉTRIQUES CIBLES
 * 
 * Qu'est-ce qu'on mesure?
 * 1. Nombre total de requêtes (par méthode, route, status code)
 * 2. Latence de chaque requête (durée en secondes)
 * 3. Mémoire utilisée par le process
 * 4. Heap memory
 */

// Métrique 1: Compteur - Total requêtes
export const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests by method, route, and status code',
  labelNames: ['method', 'route', 'status_code'],
});

// Métrique 2: Histogramme - Latence (important pour alertes!)
export const httpRequestDurationSeconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1.0, 2.0, 5.0, 10.0], // 0.1s, 0.5s, 1s, 2s, 5s, 10s
});

// Métrique 3: Jauge - Mémoire
export const processResidentMemoryBytes = new promClient.Gauge({
  name: 'process_resident_memory_bytes',
  help: 'Resident memory in bytes',
  collect() {
    const memUsage = process.memoryUsage();
    this.set(memUsage.rss); // RSS = Resident Set Size
  },
});

// Métrique 4: Jauge - Heap
export const processHeapUsedBytes = new promClient.Gauge({
  name: 'process_heap_used_bytes',
  help: 'Heap memory used in bytes',
  collect() {
    const memUsage = process.memoryUsage();
    this.set(memUsage.heapUsed);
  },
});

// Métrique 5: Jauge - Pool de connexions DB (optional)
export const databaseConnectionPoolSize = new promClient.Gauge({
  name: 'db_connection_pool_size',
  help: 'Number of active database connections',
  labelNames: ['pool_name'],
});

/**
 * MIDDLEWARE: Mesurer la latence de chaque requête
 */
@Injectable()
export class PrometheusMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    // 1. Enregistrer l'heure du début
    const start = Date.now();
    
    // 2. Sauvegarder la fonction originale res.send()
    const originalSend = res.send;

    // 3. Intercepter res.send() pour capturer la réponse
    res.send = function (data) {
      // Calculer la durée en secondes
      const duration = (Date.now() - start) / 1000;
      const statusCode = res.statusCode;
      const routePath = req.route?.path || req.path;
      const method = req.method;

      // 4. Incrémenter le compteur (http_requests_total)
      httpRequestsTotal.inc({
        method,
        route: routePath,
        status_code: statusCode,
      });

      // 5. Enregistrer la latence (http_request_duration_seconds)
      httpRequestDurationSeconds.observe(
        {
          method,
          route: routePath,
          status_code: statusCode,
        },
        duration,
      );

      // 6. Logger avec le request ID
      const requestId = req['requestId'] || 'unknown';
      console.log(
        `[${requestId}] ${method} ${routePath} - ${statusCode} (${(duration * 1000).toFixed(2)}ms)`,
      );

      // 7. Appeler la fonction originale et renvoyer les données
      res.send = originalSend;
      return res.send(data);
    };

    // Continuer au handler suivant
    next();
  }
}

/**
 * EXEMPLE: Ce que Prometheus verra
 * 
 * Frontend appelle: GET /api/goals (authifié, avec x-request-id: abc-123)
 * Backend met 42ms à répondre avec status 200
 * 
 * Prometheus métriques créées:
 * 
 * http_requests_total{method="GET", route="/api/goals", status_code="200"} 1
 * http_request_duration_seconds_bucket{method="GET", route="/api/goals", status_code="200", le="0.1"} 0
 * http_request_duration_seconds_bucket{method="GET", route="/api/goals", status_code="200", le="0.5"} 1  ✓
 * http_request_duration_seconds_bucket{method="GET", route="/api/goals", status_code="200", le="1.0"} 1
 * http_request_duration_seconds_bucket{method="GET", route="/api/goals", status_code="200", le="+Inf"} 1
 * http_request_duration_seconds_sum{method="GET", route="/api/goals", status_code="200"} 0.042
 * http_request_duration_seconds_count{method="GET", route="/api/goals", status_code="200"} 1
 * 
 * → Prometheus peut compute: P95 latency = 0.5s (ou whatever le bucket le plus proche)
 */
```

---

### Étape 4: Créer le Logger Service

**Fichier:** `src/observability/logger.service.ts`

```typescript
import { Injectable, Inject, Scope } from '@nestjs/common';
import { REQUEST } from '@nestjs/core';
import { Request } from 'express';
import * as winston from 'winston';

/**
 * Service de logging structuré avec Request ID
 * 
 * Utilisation:
 * 
 * @Controller('goals')
 * export class GoalsController {
 *   constructor(private logger: LoggerService) {}
 * 
 *   @Get()
 *   async getGoals() {
 *     this.logger.log('Fetching goals', { userId: '123' });
 *     // Output: [req-abc-123] Fetching goals userId=123
 *   }
 * }
 */
@Injectable({ scope: Scope.REQUEST })
export class LoggerService {
  private logger: winston.Logger;

  constructor(@Inject(REQUEST) private request: Request) {
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json(), // Format JSON pour Loki (Phase 2)
      ),
      defaultMeta: {
        service: 'nestjs-backend',
        environment: process.env.NODE_ENV || 'development',
      },
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.printf(({ level, message, requestId, timestamp, ...meta }) => {
              const reqId = requestId || 'none';
              const metaStr = Object.keys(meta).length ? JSON.stringify(meta) : '';
              return `[${reqId}] [${level}] ${message} ${metaStr}`;
            }),
          ),
        }),
        // Optional: Save to file (pour Promtail en Phase 2)
        // new winston.transports.File({ filename: 'logs/combined.log' }),
      ],
    });
  }

  /**
   * Extraire le request ID du contexte
   */
  private getMeta() {
    const requestId = this.request?.['requestId'];
    return requestId ? { requestId } : {};
  }

  /**
   * Log info
   * Usage: this.logger.log('User logged in', { userId: '123' })
   */
  log(message: string, meta?: any) {
    this.logger.info(message, { ...this.getMeta(), ...meta });
  }

  /**
   * Log error
   * Usage: this.logger.error('Failed to fetch goals', error, { userId: '123' })
   */
  error(message: string, error?: Error, meta?: any) {
    this.logger.error(message, {
      ...this.getMeta(),
      ...meta,
      error: {
        message: error?.message,
        stack: error?.stack,
        name: error?.name,
      },
    });
  }

  /**
   * Log warning
   */
  warn(message: string, meta?: any) {
    this.logger.warn(message, { ...this.getMeta(), ...meta });
  }

  /**
   * Log debug
   */
  debug(message: string, meta?: any) {
    this.logger.debug(message, { ...this.getMeta(), ...meta });
  }
}

/**
 * EXEMPLE DE LOGS GÉNÉRÉS
 * 
 * Frontend: GET /api/goals (avec x-request-id: req-1234)
 * 
 * Console output:
 * [req-1234] [info] Fetching goals for user userId="user-456"
 * [req-1234] [debug] Query: SELECT * FROM goals WHERE user_id = $1
 * [req-1234] [info] Found 5 goals
 * [req-1234] [info] Formatted response in 2ms
 * [req-1234] [info] GET /api/goals - 200 (42ms)
 * 
 * JSON (pour Loki):
 * {"requestId":"req-1234","level":"info","message":"Fetching goals for user","userId":"user-456",...}
 */
```

---

### Étape 5: Enregistrer les middlewares dans App Module

**Fichier:** `src/app.module.ts`

```typescript
import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { RequestIdMiddleware } from './observability/request-id.middleware';
import { PrometheusMiddleware } from './observability/prometheus.middleware';
import { LoggerService } from './observability/logger.service';

@Module({
  // ... votre config existante (controllers, services, imports, etc.)
  providers: [
    // ... votre existing providers
    LoggerService, // ✅ Ajouter ici
  ],
})
export class AppModule implements NestModule {
  /**
   * configure() est appelé au démarrage
   * On enregistre les middlewares dans l'ordre:
   * 1. RequestIdMiddleware - extrait/génère le request ID
   * 2. PrometheusMiddleware - mesure la latence
   */
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(RequestIdMiddleware)
      .forRoutes('*'); // S'applique à TOUTES les routes

    consumer
      .apply(PrometheusMiddleware)
      .forRoutes('*'); // S'applique à TOUTES les routes (après RequestId)
  }
}

/**
 * FLUX D'EXÉCUTION pour une requête:
 * 
 * Requête reçue
 *   ↓
 * RequestIdMiddleware
 *   - Lit x-request-id du frontend
 *   - L'ajoute à req.requestId
 *   - Enverrra dans réponse
 *   ↓
 * PrometheusMiddleware
 *   - Enregistre l'heure du début
 *   - Intercepte res.send()
 *   ↓
 * Votre Controller/Service
 *   - Logique métier
 *   - Utilise LoggerService
 *   ↓
 * res.send() est appelé
 *   ↓
 * PrometheusMiddleware capture la durée
 *   - Incrémente http_requests_total
 *   - Enregistre latence dans histogramme
 *   ↓
 * Réponse envoyée
 */
```

---

### Étape 6: Exposer l'endpoint `/metrics`

**Fichier:** `src/main.ts`

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { register } from 'prom-client'; // ✅ Importer

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  /**
   * ENDPOINT: GET /metrics
   * 
   * Ce que Prometheus scrape toutes les 15 secondes
   * 
   * Retourne le format Prometheus:
   * # HELP http_requests_total Total HTTP requests
   * # TYPE http_requests_total counter
   * http_requests_total{method="GET",route="/api/goals",status_code="200"} 42
   * ...
   */
  app.get('/metrics', (req, res) => {
    try {
      res.set('Content-Type', register.contentType);
      res.end(register.metrics());
    } catch (err) {
      res.status(500).end(err);
    }
  });

  /**
   * BONUS: Health check endpoint
   * Utile pour alertes (BackendDown)
   */
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
    });
  });

  const port = process.env.PORT || 3001;
  await app.listen(port);
  console.log(`🚀 Backend running on http://localhost:${port}`);
  console.log(`📊 Metrics available at http://localhost:${port}/metrics`);
  console.log(`❤️  Health check at http://localhost:${port}/health`);
}

bootstrap();

/**
 * TEST: Vérifier que c'est up
 * 
 * curl http://localhost:3001/health
 * → {"status":"ok","timestamp":"2026-04-04T14:30:00.000Z",...}
 * 
 * curl http://localhost:3001/metrics | head -20
 * → # HELP http_requests_total Total HTTP requests
 *   # TYPE http_requests_total counter
 *   http_requests_total{...} 42
 */
```

---

## 🎯 Résumé: Ajouter au Backend en 5 fichiers

| Fichier | Lignes | Rôle |
|---------|--------|------|
| `src/observability/request-id.middleware.ts` | 40 | Lire/générer request ID |
| `src/observability/prometheus.middleware.ts` | 80 | Mesurer latence |
| `src/observability/logger.service.ts` | 100 | Logger intelligent |
| `src/app.module.ts` | Modifier 20 lignes | Enregistrer middlewares |
| `src/main.ts` | Modifier 15 lignes | Exposer `/metrics` |

**Total:** ~15 minutes d'implémentation

---

## 🧪 Test: Vérifier que ça marche

### Test 1: Des métriques sont collectées

```bash
# Faire une requête
curl http://localhost:3001/api/goals

# Vérifier les métriques
curl http://localhost:3001/metrics | grep http_requests_total
# Output: http_requests_total{method="GET",route="/api/goals",status_code="200"} 1
```

### Test 2: Request ID est propagé

```bash
# Faire une requête avec request ID du frontend
curl -H "x-request-id: mon-uuid-123" http://localhost:3001/api/goals

# Vérifier dans les logs
# Output: [mon-uuid-123] GET /api/goals - 200 (45ms)

# Vérifier dans la réponse
curl -i -H "x-request-id: mon-uuid-123" http://localhost:3001/api/goals | grep x-request-id
# Output: x-request-id: mon-uuid-123
```

### Test 3: Prometheus peut scraper

```bash
# Vérifier le format Prometheus
curl http://localhost:3001/metrics | head -30
# Output: 
# # HELP http_requests_total Total HTTP requests by method, route, and status code
# # TYPE http_requests_total counter
# http_requests_total{method="GET",route="/api/goals",status_code="200"} 1
# ...
```

---

## 📊 Flux Complet Frontend ↔ Backend

```
FRONTEND (Flutter App)
├─ Génère x-request-id: abc-123
├─ Envoie: GET /api/goals
│         Headers: {
│           'x-request-id': 'abc-123',
│           'Content-Type': 'application/json',
│           'Authorization': 'Bearer token'
│         }
└─ Reçoit réponse
   Headers: {'x-request-id': 'abc-123'}  ← Echo du backend
   
   ↓

BACKEND (NestJS)
├─ RequestIdMiddleware
│  └─ Lit x-request-id: abc-123
│     Attache à req.requestId
│     Ajoute à réponse header
│
├─ PrometheusMiddleware
│  ├─ Chronomètre la requête
│  └─ Incrément counter + enregistre latence
│
├─ Controller
│  ├─ LoggerService log: "[abc-123] GET /api/goals"
│  ├─ Fetch goals from DB
│  └─ Return response (42ms)
│
└─ Response sent
   Headers: {'x-request-id': 'abc-123'}
   Status: 200
   Body: [goal1, goal2, ...]

   ↓

PROMETHEUS (scrape toutes les 15s)
├─ Lit http://localhost:3001/metrics
├─ Enregistre:
│  ├─ http_requests_total{route="/api/goals", status="200"} ++
│  ├─ http_request_duration_seconds_bucket[0.5s] ++ (42ms < 0.5s)
│  └─ Autres métriques
└─ Stocke dans TSDB (time-series database)

   ↓

GRAFANA (query Prometheus)
├─ Query: rate(http_requests_total[5m])
│  → Graph montre 2 requests/sec
│
├─ Query: histogram_quantile(0.95, ...)
│  → P95 latency = 0.5s
│
└─ Affiche dans dashboard

   ↓

ALERTMANAGER
├─ Évalue: rate(http_requests_total{status="5.."}[5m]) > 0.05
├─ Si true → Envoie alert
└─ Slack: "High error rate detected: 8%"
```

---

## 🎓 Concepts Clés

### Request ID (xyz)
- ✅ Frontend génère UUID unique par requête
- ✅ Backend reçoit dans header `x-request-id`
- ✅ Backend renvoie dans réponse (echo)
- 🎯 Permet de corréler: frontend logs ↔ backend logs ↔ Sentry events

### Métriques Prometheus
- **Counter** = Nombre cumulé (jamais décroît)
  - Exemple: total requests = 1000
- **Gauge** = Valeur à un moment (peut monter/descendre)
  - Exemple: connections actives = 5
- **Histogram** = Distribution (pour calcul de percentiles)
  - Exemple: latence 0.1s, 0.5s, 1s, 2s, 5s

### Logging Structuré
- ✅ Tous les logs incluent `requestId`
- ✅ Format JSON (pour Loki en Phase 2)
- ✅ Champs supplémentaires (userId, action, etc.)

---

## 🚀 Prochaines Étapes (Une Fois Implémenté)

1. **Tester** avec Prometheus local
   ```bash
   docker-compose -f docker-compose.observability.yml up -d
   ```

2. **Vérifier le scraping**
   - Visit http://localhost:9090/targets
   - Voir "nestjs-backend" avec status "UP"

3. **Créer la corrélation**
   - Frontend: trigger error
   - Backend: vérifier logs avec request ID
   - Sentry: check event avec request ID
   - Prometheus: check metrics
   - Loki: check logs avec request ID

---

## 📞 Questions?

**Q: Faut-il modifier toutes les requêtes HTTP?**
A: Non! Le middleware s'applique à TOUTES les routes automatiquement.

**Q: Le logging ralentit l'app?**
A: Non, Winston est async. Les logs ne bloquent pas les réponses.

**Q: Peux-on avoir des métriques custom?**
A: Oui! Créer des Counter/Gauge supplémentaires et les enregistrer dans Registry.

**Q: Pourquoi HTTP pour les métriques?**
A: Parce que Prometheus utilise HTTP pull model (chaque 15s).

---

**C'est tout ce que tu dois ajouter au backend! 🎉**
