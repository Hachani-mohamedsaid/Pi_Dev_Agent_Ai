# ✅ Observability Deployment Checklist

## 🎯 Phase 1: Frontend Observability (Sentry) - ✅ COMPLETED

### Pre-Deployment
- [x] Sentry Flutter SDK added to `pubspec.yaml` (9.16.0)
- [x] Request headers helper created (`lib/core/network/request_headers.dart`)
- [x] Sentry API reporter created (`lib/core/observability/sentry_api.dart`)
- [x] Sentry initialization in `main.dart` (conditional on SENTRY_DSN)
- [x] 25+ services patched with standardized headers

### Deployment
- [ ] **Provision Sentry DSN**
  - [ ] Go to https://sentry.io
  - [ ] Create Flutter project
  - [ ] Copy DSN string: `https://xxxx@o000.ingest.sentry.io/000`

### Testing
- [ ] **Build & Run**
  ```bash
  flutter run \
    --dart-define=SENTRY_DSN=https://xxxx@o000.ingest.sentry.io/000 \
    --dart-define=SENTRY_ENVIRONMENT=staging
  ```

- [ ] **Trigger Test Error**
  - [ ] Call API without authentication token
  - [ ] Verify 401 error appears in Sentry dashboard
  - [ ] Check request ID is captured

- [ ] **Verify Headers**
  - [ ] Inspect network request in DevTools
  - [ ] Confirm `Content-Type: application/json` present
  - [ ] Confirm `x-request-id: <uuid>` present
  - [ ] Confirm `Authorization: Bearer <token>` present (where applicable)

- [ ] **Check Response**
  - [ ] Verify backend echoes `x-request-id` in response headers
  - [ ] Confirm request ID matches in Sentry event

### Post-Deployment
- [x] Documentation complete (`docs/FLUTTER_OBSERVABILITY_FRONTEND_GUIDE.md`)
- [x] Documentation complete (`docs/NESTJS_OBSERVABILITY_RAILWAY_GUIDE.md`)
- [ ] Team trained on how to read Sentry dashboard

---

## 🎯 Phase 2: Enterprise Stack (Prometheus + Loki + Grafana + AlertManager)

### Pre-Deployment
- [x] Docker Compose stack created (`docker-compose.observability.yml`)
- [x] Prometheus configuration (`observability/prometheus.yml`)
- [x] Loki configuration (`observability/loki-config.yml`)
- [x] AlertManager configuration (`observability/alertmanager.yml`)
- [x] Promtail configuration (`observability/promtail-config.yml`)
- [x] Grafana datasources (`observability/grafana-datasources.yml`)
- [x] Pre-built dashboard (`observability/dashboards/nestjs-backend.json`)
- [x] Alert rules (`observability/alert-rules.yml`)
- [x] Documentation complete (`docs/OBSERVABILITY_PHASE2_STACK.md`)
- [x] Code templates ready (`docs/NESTJS_PROMETHEUS_INTEGRATION.ts`)

### Step 1: Configure AlertManager
- [ ] Edit `observability/alertmanager.yml`
- [ ] **Line 16-18:** Add Slack webhook
  ```yaml
  slack_configs:
    - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
  ```
- [ ] **Line 26-27** (optional): Configure email SMTP
  ```yaml
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'
  ```

### Step 2: Start the Stack
- [ ] Ensure Docker & Docker Compose installed
  ```bash
  docker --version
  docker-compose --version
  ```

- [ ] Start all services
  ```bash
  docker-compose -f docker-compose.observability.yml up -d
  ```

- [ ] Verify all containers running
  ```bash
  docker-compose -f docker-compose.observability.yml ps
  # All 5 services should show "Up"
  ```

### Step 3: Backend Integration (NestJS)
- [ ] **Install dependencies**
  ```bash
  npm install prom-client winston
  ```

- [ ] **Copy Prometheus middleware**
  - [ ] Copy `RequestIdMiddleware` from `docs/NESTJS_PROMETHEUS_INTEGRATION.ts`
  - [ ] Create file: `src/observability/request-id.middleware.ts`
  - [ ] Copy `PrometheusMiddleware` from template
  - [ ] Create file: `src/observability/prometheus.middleware.ts`

- [ ] **Copy Logger service**
  - [ ] Copy `LoggerService` from template
  - [ ] Create file: `src/observability/logger.service.ts`

- [ ] **Register middleware in App Module**
  - [ ] Edit `src/app.module.ts`
  - [ ] Add imports for both middlewares
  - [ ] Register in `configure()` method

- [ ] **Expose /metrics endpoint**
  - [ ] Edit `src/main.ts`
  - [ ] Add `/metrics` route that returns `register.metrics()`
  - [ ] Add `/health` check endpoint

- [ ] **Test metrics endpoint**
  ```bash
  curl http://localhost:3001/metrics | head -20
  # Should see lines like:
  # # HELP http_requests_total Total HTTP requests
  # # TYPE http_requests_total counter
  # http_requests_total{...} 42
  ```

### Step 4: Verify Prometheus Scraping
- [ ] Visit http://localhost:9090/targets
- [ ] Verify `nestjs-backend` target shows "UP" (green)
  - If "DOWN": Check NestJS is running on port 3001

- [ ] Visit http://localhost:9090/graph
- [ ] Query: `rate(http_requests_total[5m])`
  - Should return non-zero results if backend has traffic

### Step 5: Verify Loki Logging
- [ ] Visit http://localhost:3100/ready
  - Should return 200 OK

- [ ] Backend logs should flow through Promtail
  - [ ] Send a request to backend: `curl http://localhost:3001/health`
  - [ ] Check Loki has logs: `curl http://localhost:3100/loki/api/v1/label/job/values`

### Step 6: Verify Grafana
- [ ] Open http://localhost:3000
- [ ] **Login**
  - Username: `admin`
  - Password: `admin`
  - Prompted to change password (do it)

- [ ] **Verify datasources configured**
  - [ ] Click Settings → Data Sources
  - [ ] Should see: Prometheus, Loki, AlertManager
  - [ ] All should show "green" (connection OK)

- [ ] **View pre-built dashboard**
  - [ ] Click Home → "NestJS Backend Performance" dashboard
  - [ ] Should see 4 panels:
    - Request Rate (should show bars if backend has traffic)
    - Error Rate (should show 0 if no errors)
    - Latency Percentiles (p50, p95, p99)
    - Memory Usage (should show upward trend)

### Step 7: Test Alerting
- [ ] **Trigger a test alert**
  - [ ] Edit `observability/alert-rules.yml`
  - [ ] Change one threshold to something easy to trigger:
    ```yaml
    - alert: TestAlert
      expr: http_requests_total > 0  # Always true if backend has traffic
      for: 1m
    ```

- [ ] **Wait 1-2 minutes**
  - Alert should appear in AlertManager: http://localhost:9093

- [ ] **Verify Slack notification**
  - [ ] Slack channel should receive alert message
  - [ ] Alert is labeled "Alert: TestAlert"

- [ ] **Restore alert rule** (revert test threshold change)

### Step 8: Create Custom Dashboard (Optional)
- [ ] Visit http://localhost:3000
- [ ] Click **+** → **Dashboard**
- [ ] Click **Add Panel**
- [ ] Select **Prometheus** datasource
- [ ] Use example queries:
  ```promql
  # Request rate
  rate(http_requests_total[5m])
  
  # Error rate
  rate(http_requests_total{status=~"5.."}[5m])
  
  # P95 latency (milliseconds)
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) * 1000
  ```
- [ ] Add title & save

---

## 🎯 Integration Verification

### End-to-End Test
- [ ] **Frontend sends request with x-request-id**
  - [ ] Open DevTools Network tab
  - [ ] Make API call
  - [ ] Inspect request headers
  - [ ] Confirm `x-request-id: <uuid>` present

- [ ] **Backend logs contain request ID**
  - [ ] Check backend logs
  - [ ] Should show: `[<uuid>] GET /api/endpoint - 200`

- [ ] **Prometheus captures metrics**
  - [ ] Visit http://localhost:9090/graph
  - [ ] Query: `http_requests_total`
  - [ ] Should show metrics from recent requests

- [ ] **Loki shows logs**
  - [ ] Visit http://localhost:3000 (Grafana)
  - [ ] Click **Explore** → Select **Loki**
  - [ ] Query: `{job="nestjs"}`
  - [ ] Should show recent backend logs

- [ ] **Grafana dashboard updates**
  - [ ] View NestJS Backend Performance dashboard
  - [ ] Panels should show real data

- [ ] **Correlation works**
  - [ ] Trigger a 401 error (call API without token)
  - [ ] Check Sentry: event has feature tag + request ID
  - [ ] Check Prometheus: `http_requests_total{status="401"}` incremented
  - [ ] Check Loki: logs show `401 Unauthorized` with request ID

---

## 📋 Post-Deployment

### Documentation
- [ ] Team has access to `OBSERVABILITY_COMPLETE_ROADMAP.md`
- [ ] Backend team reviewed `docs/OBSERVABILITY_PHASE2_STACK.md`
- [ ] On-call team trained on alert routing
- [ ] Runbooks created for each alert type

### Monitoring
- [ ] Check alerts for 24 hours (adjust thresholds as needed)
- [ ] Verify Slack notifications work
- [ ] Test escalation (warning → critical)

### Dashboards
- [ ] Create team-specific dashboards
- [ ] Add business metrics (goals, challenges, etc.)
- [ ] Create on-call runbook dashboard

### Optimization
- [ ] Tune alert thresholds based on baseline
- [ ] Add custom metrics for business KPIs
- [ ] Archive old logs (if using external storage)

---

## 🆘 Troubleshooting

| Issue | Diagnosis | Fix |
|-------|-----------|-----|
| Prometheus shows no targets | `curl http://localhost:9090/targets` | Verify NestJS running on port 3001 |
| AlertManager not sending Slack | Test webhook manually | Add correct Slack webhook URL |
| Loki not receiving logs | `docker logs promtail` | Verify Promtail container running |
| Grafana tables empty | Check datasource connection | Restart Grafana: `docker-compose restart grafana` |
| High memory in Prometheus | Check retention settings | Reduce `retention_period` or `scrape_interval` |

---

## ✅ Final Sign-Off

- [ ] Phase 1 & Phase 2 deployed successfully
- [ ] All alerts tested & routed correctly
- [ ] Team trained on dashboards
- [ ] Incident response process documented
- [ ] On-call runbooks prepared

**Ready for production!** 🚀
