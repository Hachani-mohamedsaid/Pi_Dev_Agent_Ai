# 📊 Observability Stack - Quick Start

## 🚀 5-Minute Setup

### 1. Configure AlertManager (Required for notifications)

```bash
# Copy environment template
cp observability/.env.template observability/.env

# Edit and add your Slack webhook
nano observability/alertmanager.yml
# Replace: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### 2. Start the Stack

```bash
docker-compose -f docker-compose.observability.yml up -d
```

### 3. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | None |
| **AlertManager** | http://localhost:9093 | None |
| **Loki** | http://localhost:3100 | None |

---

## 📋 What's Included

✅ **Prometheus** — Metrics storage & scraping  
✅ **Loki** — Centralized log aggregation  
✅ **Grafana** — Dashboards & visualization  
✅ **AlertManager** — Alert routing & notifications  
✅ **Promtail** — Log forwarding (Docker → Loki)  

---

## 🔌 Next: Backend Integration

See [`docs/OBSERVABILITY_PHASE2_STACK.md`](../docs/OBSERVABILITY_PHASE2_STACK.md) for:
- Installing Prometheus metrics middleware in NestJS
- Configuring request ID propagation
- Custom dashboard creation
- Alert rules explanation

---

## ⚡ Common Commands

```bash
# View stack status
docker-compose -f docker-compose.observability.yml ps

# View logs
docker-compose -f docker-compose.observability.yml logs -f [service]

# Stop stack
docker-compose -f docker-compose.observability.yml down

# Restart single service
docker-compose -f docker-compose.observability.yml restart prometheus
```

---

## 🎯 File Structure

```
observability/
├── docker-compose.observability.yml  # Main compose file
├── prometheus.yml                     # Prometheus config
├── alert-rules.yml                    # Alert rules
├── alertmanager.yml                   # AlertManager config
├── loki-config.yml                    # Loki config
├── promtail-config.yml                # Promtail config
├── grafana-datasources.yml            # Grafana datasources
├── grafana-dashboards.yml             # Grafana dashboard loader
├── dashboards/
│   └── nestjs-backend.json            # Pre-configured dashboard
└── .env.template                      # Environment variables template
```

---

## 🆘 Troubleshooting

**Prometheus not scraping?**
```bash
curl http://localhost:9090/api/v1/targets
# Check "UP" status for nestjs-backend target
```

**AlertManager not sending to Slack?**
```bash
# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  YOUR_SLACK_WEBHOOK_URL
```

**Loki not getting logs?**
```bash
docker logs promtail
```

---

## 📖 Full Documentation

See [`docs/OBSERVABILITY_PHASE2_STACK.md`](../docs/OBSERVABILITY_PHASE2_STACK.md) for:
- Detailed deployment steps
- NestJS backend integration code
- Grafana custom queries
- Scaling considerations
- Production setup

---

## 🔗 Related Documentation

- Phase 1 (Sentry): [`docs/NESTJS_OBSERVABILITY_RAILWAY_GUIDE.md`](../docs/NESTJS_OBSERVABILITY_RAILWAY_GUIDE.md)
- Frontend: [`docs/FLUTTER_OBSERVABILITY_FRONTEND_GUIDE.md`](../docs/FLUTTER_OBSERVABILITY_FRONTEND_GUIDE.md)
