# Backend Observability Guide

## Objective

This backend guide explains how to make the NestJS API observable and how it works with the Flutter frontend.

The goal is to:
- trace each request end-to-end with a request id
- export metrics to Prometheus
- show dashboards in Grafana
- route alerts with Alertmanager
- keep logs correlated with the same request id

---

## What the frontend sends

The Flutter app already sends these headers on every API call:

- `x-request-id`: unique id per request
- `x-client-source`: `flutter-web`, `flutter-ios`, `flutter-android`, etc.
- `x-app-version`: optional app version
- `Authorization`: bearer token when the user is authenticated

The backend must read these headers, store them in logs/metrics, and echo `x-request-id` in responses.

---

## What the backend must do

### 1. Read and propagate `x-request-id`

If the frontend sends a request id:
- reuse it
- attach it to the request context
- return it in the response headers

If it is missing:
- generate a new one
- attach it to the request context
- return it in the response headers

### 2. Collect Prometheus metrics

The backend should expose at least:

- request counter
- request duration histogram
- memory usage
- optional CPU usage
- optional active users

### 3. Write structured logs

Every log line should include:
- request id
- client source
- route
- method
- status code
- latency

### 4. Expose `/metrics`

Prometheus scrapes this endpoint regularly.

### 5. Expose `/health`

Useful for health checks, uptime monitoring, and Grafana status panels.

---

## Recommended backend files

Create these files in the NestJS backend:

- `src/observability/request-id.middleware.ts`
- `src/observability/prometheus.middleware.ts`
- `src/observability/logger.service.ts`
- `src/app.module.ts`
- `src/main.ts`

Optional:

- `src/observability/business-metrics.service.ts`
- `src/observability/metrics.controller.ts`

---

## Metrics model

### Core metrics

#### Request counter

```text
http_requests_total{method, route, status_code, source}
```

Example:

```text
http_requests_total{method="GET", route="/api/goals", status_code="200", source="flutter-web"} 42
```

#### Request latency histogram

```text
http_request_duration_seconds{method, route, status_code, source}
```

This metric is used to calculate p95 / p99 latency in Grafana.

#### Memory

```text
process_resident_memory_bytes
process_heap_used_bytes
```

### Optional custom metrics

If you want to show business data:

```text
app_active_users
app_total_users
app_active_sessions
app_requests_by_source
```

These must be defined by the backend business logic.

---

## PromQL queries for Grafana

### 1. Request rate

```promql
sum(rate(http_requests_total[5m]))
```

### 2. Request rate by route

```promql
sum by (route) (rate(http_requests_total[5m]))
```

### 3. Request rate by source

```promql
sum by (source) (rate(http_requests_total[5m]))
```

### 4. Frontend traffic only

```promql
sum(rate(http_requests_total{source=~"flutter-.*"}[5m]))
```

### 5. 5xx error rate

```promql
sum(rate(http_requests_total{status_code=~"5.."}[5m]))
```

### 6. Frontend P95 latency

```promql
histogram_quantile(
  0.95,
  sum by (le) (rate(http_request_duration_seconds_bucket{source=~"flutter-.*"}[5m]))
)
```

### 7. Memory usage

```promql
process_resident_memory_bytes
```

### 8. CPU usage

```promql
process_cpu_seconds_total
```

---

## Grafana panels to create

### Stat panels

- Backend Up
- Active Users
- CPU
- Memory

### Time series panels

- Request Rate
- Latency P95
- Error Rate
- CPU / Memory over time

### Bar chart panels

- Requests by Route
- Requests by Source
- Errors by Status Code

### Table panels

- Recent errors
- Slow routes
- Top routes by traffic

### Unified frontend + backend dashboard

Use this dashboard file from this repository:

- `observability/dashboards/frontend-backend-unified.json`

It includes:

- Stat: Backend Up
- Stat: Frontend Request Rate
- Stat: Frontend P95 Latency
- Stat: Frontend 5xx Rate
- Time series: Requests by Source
- Time series: P95 Latency by Source
- Bar chart: 5xx Errors by Source
- Time series: Backend Memory

If some panels show no data, check:

- backend metrics endpoint is up
- Prometheus target `nestjs-backend` is `UP`
- frontend requests are being generated
- `source` label is exported in backend metrics

### Which panel type to use

- Stat: single KPI now (up/down, p95 now, req/s now)
- Time series: trends over time (rate, latency, memory)
- Bar chart: compare categories at a glance (errors by source)
- Table: troubleshooting details by route/status/source

---

## Backend middleware behavior

### RequestIdMiddleware

Responsibilities:
- read `x-request-id`
- generate one if missing
- attach it to the request
- send it back in the response headers

### PrometheusMiddleware

Responsibilities:
- measure request duration
- increment counters
- record latency histogram
- tag metrics by route, method, status code, and source

### LoggerService

Responsibilities:
- write structured logs
- include request id and source
- keep logs JSON-friendly for Loki/Grafana

---

## Test flow

### 1. Start the backend

```bash
npm run start:dev
```

### 2. Check health

```bash
curl http://localhost:3001/health
```

Expected response:

```json
{
  "status": "ok"
}
```

### 3. Check metrics

```bash
curl http://localhost:3001/metrics | head -30
```

Expected output:

- `# HELP http_requests_total ...`
- `# TYPE http_requests_total counter`
- request metrics lines

### 4. Generate traffic from frontend

- open the Flutter app
- navigate across screens
- call API endpoints

### 5. Verify in Prometheus

Open:

- `http://localhost:9090`

Run queries like:

```promql
up
```

```promql
sum(rate(http_requests_total[5m]))
```

### 6. Verify in Grafana

Open:

- `http://localhost:3001`

Check dashboards:
- request rate
- latency
- CPU
- memory
- source breakdown

For unified monitoring, import:

- `observability/dashboards/frontend-backend-unified.json`

---

## Common problems

### Prometheus shows no data

Possible causes:
- backend does not expose `/metrics`
- Prometheus target is down
- labels in PromQL do not match the metric names
- no traffic has been generated yet

### Grafana shows "No data"

Possible causes:
- wrong dashboard query
- no recent requests
- metrics not scraped yet

### Alertmanager receives nothing

Possible causes:
- alert rules not configured
- webhook not set
- threshold too high to trigger

### Frontend not visible in dashboards

Possible causes:
- `x-client-source` not sent
- backend not reading the header
- PromQL query not filtering on `source`

---

## Recommended implementation order

1. add request id middleware
2. expose `/metrics`
3. add request counter and latency histogram
4. add `source` label
5. connect Grafana panels
6. add alert rules
7. add business metrics like active users

---

## Suggested production labels

Use these label values consistently:

- `source="flutter-web"`
- `source="flutter-ios"`
- `source="flutter-android"`
- `source="backend-job"`
- `source="internal-api"`

This makes Grafana filtering much cleaner.

---

## Final check list

- [ ] `x-request-id` is echoed by backend
- [ ] `x-client-source` is visible in metrics
- [ ] `/metrics` is up
- [ ] `/health` is up
- [ ] Prometheus target is `UP`
- [ ] Grafana dashboard shows data
- [ ] Logs include request id and source
- [ ] Alerts can fire through Alertmanager

---

## Summary

To make backend monitoring useful, the backend must not only expose metrics, but also tag them with request id and client source. That is what lets you separate Flutter frontend traffic from other clients, and it is what makes Grafana dashboards readable.
