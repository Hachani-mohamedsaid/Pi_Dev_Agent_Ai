# 🎯 Observability Phase 2: Complete Stack (Prometheus + Loki + Grafana + AlertManager)

## Overview

This Phase 2 extends the basic Sentry observability (Phase 1) with a complete on-premises monitoring stack:

| Component | Purpose | Port |
|-----------|---------|------|
| **Prometheus** | Scrape & store metrics (CPU, RAM, latency, error rates) | 9090 |
| **Loki** | Centralized log aggregation (alternative to CloudWatch) | 3100 |
| **Grafana** | Visual dashboards & alerting UI | 3000 |
| **AlertManager** | Alert routing & notification engine | 9093 |
| **Promtail** | Log forwarder (Docker → Loki) | 9080 |

---

## 📋 Deployment Checklist

### Step 1: Prerequisites

```bash
# Ensure Docker & Docker Compose installed
docker --version
docker-compose --version

# Navigate to project root
cd /Users/mohamedsaidhachani/development/Pi_Dev_Agent_Ai
```

### Step 2: Configure AlertManager (CRITICAL)

**File:** `observability/alertmanager.yml`

1. **Slack Integration:**
   - Get webhook URL: https://api.slack.com/messaging/webhooks
   - Replace placeholders in alertmanager.yml:
     ```yaml
     api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
     ```

2. **Email Integration (optional):**
   ```yaml
   smtp_smarthost: 'smtp.gmail.com:587'
   smtp_auth_username: 'your-email@gmail.com'
   smtp_auth_password: 'your-app-password'  # Use app-specific password for Gmail
   ```

3. **PagerDuty Integration (optional):**
   - Get service key from PagerDuty dashboard
   - Uncomment & configure pagerduty_configs

### Step 3: Configure Prometheus

**File:** `observability/prometheus.yml`

```yaml
scrape_configs:
  - job_name: 'nestjs-backend'
    static_configs:
      - targets:
          - 'localhost:3001'  # UPDATE: Your NestJS port
```

### Step 4: Start the Stack

```bash
# Start all containers
docker-compose -f docker-compose.observability.yml up -d

# Verify all services are running
docker-compose -f docker-compose.observability.yml ps

# View logs (optional)
docker-compose -f docker-compose.observability.yml logs -f
```

Expected output:
```
prometheus     running (port 9090)
loki           running (port 3100)
promtail       running (port 9080)
alertmanager   running (port 9093)
grafana        running (port 3000)
```

### Step 5: Access Grafana Dashboard

1. **URL:** http://localhost:3000
2. **Default Credentials:**
   - Username: `admin`
   - Password: `admin`
3. **Change password on first login** (required)
4. **Pre-configured dashboards:**
   - NestJS Backend Performance (auto-loaded from `observability/dashboards/`)
   - Prometheus targets health check
   - Alert status overview

---

## 🔌 Backend Integration (NestJS)

### Step 1: Install Prometheus Metrics

```bash
cd backend/
npm install prom-client
```

### Step 2: Create Metrics Middleware

**File:** `src/observability/prometheus.middleware.ts`

```typescript
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as promClient from 'prom-client';

// Create metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

const httpRequestDurationSeconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5],
});

const processResidentMemoryBytes = new promClient.Gauge({
  name: 'process_resident_memory_bytes',
  help: 'Resident memory in bytes',
});

@Injectable()
export class PrometheusMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    const originalSend = res.send;

    res.send = function (data) {
      const duration = (Date.now() - start) / 1000;
      const statusCode = res.statusCode;

      httpRequestsTotal.inc({
        method: req.method,
        route: req.route?.path || req.path,
        status_code: statusCode,
      });

      httpRequestDurationSeconds.observe(
        {
          method: req.method,
          route: req.route?.path || req.path,
          status_code: statusCode,
        },
        duration,
      );

      res.send = originalSend;
      return res.send(data);
    };

    next();
  }
}
```

### Step 3: Register Middleware in App Module

**File:** `src/app.module.ts`

```typescript
import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { PrometheusMiddleware } from './observability/prometheus.middleware';

@Module({
  // ... existing config
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(PrometheusMiddleware).forRoutes('*');
  }
}
```

### Step 4: Expose Metrics Endpoint

**File:** `src/main.ts`

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { register } from 'prom-client';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Expose Prometheus metrics endpoint
  app.get('/metrics', (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(register.metrics());
  });

  await app.listen(3001);
}
bootstrap();
```

### Step 5: Include Request ID in Logs

**File:** `src/observability/logger.middleware.ts`

```typescript
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const requestId = req.headers['x-request-id'] || uuidv4();
    req['requestId'] = requestId;
    res.setHeader('x-request-id', requestId);
    
    // Log with requestId
    console.log(`[${requestId}] ${req.method} ${req.url}`);
    
    next();
  }
}
```

---

## 📊 Predefined Alerts

All alerts configured in `observability/alert-rules.yml`:

### 🔴 Critical Alerts (Immediate Notification)

| Alert | Threshold | Receivers |
|-------|-----------|-----------|
| **HighErrorRate** | Error rate > 5% for 5m | ops-critical |
| **BackendServiceDown** | Service down > 1m | ops-critical |
| **DBConnectionPoolExhausted** | Connections > 90/100 | dba-team |

### 🟡 Warning Alerts (4-hour repeat)

| Alert | Threshold | Receivers |
|-------|-----------|-----------|
| **HighLatency** | P95 latency > 1s | dev-team |
| **HighMemoryUsage** | Memory > 1GB | dev-team |
| **RequestQueueBacklog** | Requests/sec > 100 | dev-team |

### 🔒 Security Alerts (2-hour repeat)

| Alert | Threshold |
|-------|-----------|
| **AuthenticationFailures** | 401 errors > 10% of requests |
| **SentryErrorSpike** | Error rate > 1/sec |

---

## 🎨 Grafana Dashboards

### Auto-Loaded Dashboards

1. **NestJS Backend Performance** (`nestjs-backend.json`)
   - Request rate (graph)
   - Error rate by status code (5xx, 4xx)
   - Latency percentiles (p50, p95, p99)
   - Memory usage trend

2. **Prometheus Health** (built-in)
   - Active scrape targets
   - Scrape duration
   - Sample ingestion rate

### Custom Dashboard Creation

In Grafana:
1. Click **+** → **Dashboard**
2. Click **Add Panel**
3. Select **Prometheus** as datasource
4. Example queries:
   ```promql
   # Error rate last 5 minutes
   rate(http_requests_total{status=~"5.."}[5m])
   
   # P95 latency
   histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
   
   # Memory usage
   process_resident_memory_bytes / (1024 * 1024 * 1024)
   ```

---

## 📝 Log Queries in Loki

### In Grafana, select Loki datasource and use LogQL:

```logql
# All errors in last hour
{level="ERROR"} | json | line_format "{{ .timestamp }} - {{ .message }}"

# NestJS backend logs with request ID
{job="nestjs"} | json | line_format "[{{ .requestId }}] {{ .message }}"

# Authentication failures
{job="nestjs"} | json | line_format "{{ .level }}: {{ .message }}" | line =~ "401|unauthorized"

# Logs from specific service
{service="auth"} | json
```

---

## 🔧 Troubleshooting

### Prometheus not scraping metrics

```bash
# Check Prometheus UI: http://localhost:9090/targets
# All should show "UP" status

# If Down - verify NestJS metrics endpoint:
curl http://localhost:3001/metrics
```

### AlertManager not sending notifications

```bash
# Check AlertManager UI: http://localhost:9093
# Verify webhook URL in alertmanager.yml
# Test Slack webhook:
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test Alert"}' \
  https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### Loki not receiving logs

```bash
# Check Promtail is running
docker logs promtail

# Verify Docker socket access
ls -la /var/run/docker.sock
```

---

## 📈 Recommended Metrics to Track

### Application Metrics

```promql
# Business metrics
rate(api_calls_total{endpoint="/api/goals"}[5m])        # Goal API traffic
rate(api_calls_total{endpoint="/api/challenges"}[5m])   # Challenge API traffic

# Performance metrics
histogram_quantile(0.95, http_request_duration_seconds) # P95 latency
rate(http_requests_total{status=~"5.."}[5m])            # Error rate

# Resource metrics
process_resident_memory_bytes                            # Memory
process_cpu_seconds_total                                # CPU time
```

### Infrastructure Metrics

```promql
node_memory_MemAvailable_bytes        # System memory available
node_cpu_seconds_total                 # CPU time
node_network_receive_bytes_total       # Network I/O
```

---

## 🚀 Scaling Considerations

### For Production:

1. **External Storage:**
   - Replace `filesystem` in Loki with S3/GCS
   - Replace `boltdb-shipper` with managed Prometheus (Grafana Cloud)

2. **High Availability:**
   - Run Prometheus & Loki in replica sets
   - Use load balancer for Grafana
   - Configure AlertManager to notify multiple channels

3. **Cost Optimization:**
   - Adjust `retention_period` in Loki (currently unlimited)
   - Reduce `scrape_interval` from 15s to 30s+ in production
   - Enable `rate limiting` for log ingestion

4. **Security:**
   - Enable HTTPS for all services
   - Add authentication (Oauth2, LDAP)
   - Use network policies to restrict traffic

---

## 📚 Further Reading

- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [Loki Query Language (LogQL)](https://grafana.com/docs/loki/latest/logql/)
- [AlertManager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Dashboarding](https://grafana.com/docs/grafana/latest/dashboards/)

---

## 🎯 Phase 1 + Phase 2 Integration

**Frontend (Flutter):**
- Sentry captures errors + request IDs ✅

**Backend (NestJS):**
- Prometheus metrics + request ID middleware (Phase 2)
- Loki aggregates logs (Phase 2)
- Sentry captures backend exceptions (Phase 1)

**Correlation Flow:**
```
Frontend Error → Sentry (with x-request-id)
               ↓
Backend receives request with x-request-id
               ↓
Logs with request ID → Loki
               ↓
Metrics (latency, errors) → Prometheus
               ↓
Grafana shows unified view + Alerts fire
```
