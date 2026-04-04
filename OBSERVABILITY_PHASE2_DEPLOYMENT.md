# 🎯 Phase 2 Observability Stack - Complete Deployment Guide

## 📦 What's Been Created

### 1. **Docker Compose Orchestration**
- `docker-compose.observability.yml` — Launches all 5 services (Prometheus, Loki, Grafana, AlertManager, Promtail)

### 2. **Prometheus Configuration**
- `observability/prometheus.yml` — Scrape targets, retention, evaluation intervals
- `observability/alert-rules.yml` — 8 predefined alert rules (error rate, latency, memory, auth failures, etc.)

### 3. **AlertManager Configuration**
- `observability/alertmanager.yml` — Alert routing (critical → Slack, warnings → email, etc.)
- Supports: Slack, Email, PagerDuty, custom webhooks

### 4. **Loki Log Aggregation**
- `observability/loki-config.yml` — Log storage, retention, ingestion limits
- `observability/promtail-config.yml` — Docker log forwarding, JSON parsing, field extraction

### 5. **Grafana Dashboarding**
- `observability/grafana-datasources.yml` — Auto-configure Prometheus, Loki, AlertManager
- `observability/grafana-dashboards.yml` — Auto-load dashboards from directory
- `observability/dashboards/nestjs-backend.json` — Pre-built dashboard with:
  - Request rate graph
  - Error rate by status code
  - Latency percentiles (p50, p95, p99)
  - Memory usage trend

### 6. **Documentation**
- `docs/OBSERVABILITY_PHASE2_STACK.md` — **270+ lines** of comprehensive deployment guide
  - Step-by-step setup (5 steps)
  - NestJS backend integration code snippets
  - Alert explanation & custom rules
  - Grafana dashboard creation guide
  - LogQL query examples
  - Production scaling checklist
  
- `docs/NESTJS_PROMETHEUS_INTEGRATION.ts` — **Copy-paste ready** code templates:
  - Prometheus middleware (metrics collection)
  - Request ID middleware
  - Logger service (structured logging)
  - Database connection pool tracking
  - App bootstrap with `/metrics` endpoint
  - Example Prometheus queries for Grafana

- `observability/README.md` — Quick start (5 min setup)
- `observability/.env.template` — Configuration template

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Edit AlertManager
```bash
# Replace Slack webhook in:
nano observability/alertmanager.yml
# Line ~16: api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
```

### Step 2: Start the Stack
```bash
docker-compose -f docker-compose.observability.yml up -d
```

### Step 3: Access Services
| Service | URL |
|---------|-----|
| Grafana (dashboard) | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| AlertManager | http://localhost:9093 |
| Loki | http://localhost:3100 |

### Step 4: Integrate Backend (NestJS)
Copy code from `docs/NESTJS_PROMETHEUS_INTEGRATION.ts` to your backend:
1. Install: `npm install prom-client winston`
2. Create middlewares (copy from template)
3. Register in `app.module.ts`
4. Expose `/metrics` endpoint in `main.ts`

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         GRAFANA (3000)                          │
│                  ┌─────────────────────────────┐                │
│                  │  Dashboards                 │                │
│                  │  - Performance metrics      │                │
│                  │  - Log viewer               │                │
│                  │  - Alert status             │                │
│                  └─────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
         ↑                    ↑                           ↑
         │                    │                           │
    Prometheus (9090)    Loki (3100)            AlertManager (9093)
         ↑                    ↑                           ↑
         │                    │                           │
    Metrics from          Docker logs              Alert rules
    /metrics endpoint      from Promtail           fire Slack/Email
         ↑                    ↑
         │                    │
    ┌────────────────────┴────────────────────┐
    │  NestJS Backend (3001)                  │
    │  ├─ /metrics endpoint (Prometheus)      │
    │  ├─ Prometheus middleware (latency)     │
    │  ├─ Request ID middleware (correlation)│
    │  ├─ Structured logging (Winston)       │
    │  └─ Database pool tracking             │
    └────────────────────────────────────────┘
```

---

## 🔔 Alerts Included

### Critical (Immediate Slack notification)
- **HighErrorRate** — 5xx errors > 5% for 5 minutes
- **BackendServiceDown** — Service unreachable > 1 minute
- **DBConnectionPoolExhausted** — Connections > 90/100

### Warning (4-hour repeat)
- **HighLatency** — P95 latency > 1 second
- **HighMemoryUsage** — Memory > 1GB
- **RequestQueueBacklog** — > 100 requests/sec

### Security (2-hour repeat)
- **AuthenticationFailures** — 401 errors > 10%
- **SentryErrorSpike** — > 1 error/sec in Sentry

---

## 📈 Integration with Phase 1

**Phase 1 (Sentry):**
- Frontend errors captured with `x-request-id`
- Backend Sentry initialized

**Phase 2 (This Stack):**
- Backend metrics collected in Prometheus
- Backend logs aggregated in Loki
- Unified dashboards in Grafana
- Alerts routed via AlertManager

**Correlation:**
```
Frontend Error → Sentry (request ID)
              ↓
Backend processes request
              ↓
Logs & metrics tagged with request ID
              ↓
Grafana correlates all data
              ↓
Single incident view: frontend + backend
```

---

## 📝 Files Created/Modified

### New Files
```
docker-compose.observability.yml          (87 lines)
observability/prometheus.yml              (55 lines)
observability/alert-rules.yml             (100 lines)
observability/alertmanager.yml            (110 lines)
observability/loki-config.yml             (40 lines)
observability/promtail-config.yml         (80 lines)
observability/grafana-datasources.yml     (35 lines)
observability/grafana-dashboards.yml      (20 lines)
observability/dashboards/nestjs-backend.json   (350 lines)
observability/README.md                   (100 lines)
observability/.env.template               (50 lines)
docs/OBSERVABILITY_PHASE2_STACK.md        (270 lines)
docs/NESTJS_PROMETHEUS_INTEGRATION.ts     (280 lines)
```

---

## ✅ Next Steps

1. **Configure AlertManager** (5 min)
   - Edit `observability/alertmanager.yml`
   - Add Slack webhook URL

2. **Start Stack** (1 min)
   ```bash
   docker-compose -f docker-compose.observability.yml up -d
   ```

3. **Backend Integration** (15 min)
   - Follow `docs/NESTJS_PROMETHEUS_INTEGRATION.ts`
   - Copy middleware code
   - Add `/metrics` endpoint

4. **Create Custom Dashboards** (Optional)
   - Visit Grafana at http://localhost:3000
   - Add panels with your own Prometheus queries

5. **Setup Alerts** (Optional)
   - Edit `observability/alert-rules.yml`
   - Customize thresholds for your app

---

## 📚 Documentation Links

- **Quick Start:** `observability/README.md`
- **Detailed Deployment:** `docs/OBSERVABILITY_PHASE2_STACK.md`
- **Backend Code (copy-paste):** `docs/NESTJS_PROMETHEUS_INTEGRATION.ts`
- **Phase 1 (Sentry):** `docs/NESTJS_OBSERVABILITY_RAILWAY_GUIDE.md`
- **Frontend:** `docs/FLUTTER_OBSERVABILITY_FRONTEND_GUIDE.md`

---

## 🎯 Key Metrics to Monitor

```promql
# Request rate
rate(http_requests_total[5m])

# Error rate by status
rate(http_requests_total{status=~"5.."}[5m])

# Latency percentiles
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage
process_resident_memory_bytes / (1024^3)

# Database connections
db_connection_pool_size
```

---

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Prometheus not scraping | Check `http://localhost:9090/targets` — target should be "UP" |
| AlertManager not sending Slack | Verify webhook URL in `alertmanager.yml` |
| Loki not receiving logs | Check Promtail: `docker logs promtail` |
| Grafana won't load | Restart: `docker-compose -f docker-compose.observability.yml restart grafana` |
| High memory usage in Prometheus | Reduce `retention_deletes_enabled` or lower `retention_period` |

---

## 🚀 Production Deployment (Future)

For production, consider:
1. Use managed services (Grafana Cloud, AWS Managed Prometheus)
2. Add high availability via replicas
3. Enable HTTPS for all services
4. Add authentication (OAuth2, LDAP)
5. Configure external storage (S3, GCS)
6. Set up alerting escalation policies

See "Scaling Considerations" section in `docs/OBSERVABILITY_PHASE2_STACK.md`

---

**Status:** ✅ Phase 2 Complete  
**All files ready for deployment**  
**Next: Configure AlertManager & start the stack**
