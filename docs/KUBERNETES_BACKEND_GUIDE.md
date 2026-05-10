# Kubernetes Backend Guide

## Where Kubernetes belongs

For this project, Kubernetes should be applied to the backend and infrastructure layer, not to the Flutter frontend code.

### Recommended placement

- **Backend API**: Kubernetes Deployment, Service, Ingress, ConfigMap, Secret, HPA
- **Observability stack**: Prometheus, Grafana, Loki, Alertmanager
- **Frontend Flutter**:
  - if you deploy Flutter web, it can be served as a static site behind Nginx or a CDN
  - if you deploy mobile apps, Kubernetes is not needed

---

## Why backend first

Kubernetes is most useful for:

- scaling API pods
- restarting unhealthy backend containers
- exposing backend services securely
- managing environment variables and secrets
- attaching monitoring and alerting

That means the backend should be the first thing to move to K8s.

---

## Suggested repository structure in the backend repo

If you have a separate NestJS backend repository, create:

```text
k8s/
  namespace.yaml
  configmap.yaml
  secret.yaml
  deployment.yaml
  service.yaml
  ingress.yaml
  hpa.yaml
  prometheus-servicemonitor.yaml
```

Optional for observability:

```text
k8s/observability/
  grafana-deployment.yaml
  grafana-service.yaml
  prometheus-deployment.yaml
  prometheus-service.yaml
  alertmanager-deployment.yaml
  alertmanager-service.yaml
  loki-deployment.yaml
  loki-service.yaml
```

---

## What each file does

### 1. namespace.yaml

Creates a dedicated namespace such as:

```yaml
metadata:
  name: my-app
```

### 2. configmap.yaml

Stores non-sensitive configuration:

- `NODE_ENV`
- `PORT`
- backend base URLs
- feature flags
- Prometheus scrape settings

### 3. secret.yaml

Stores sensitive values:

- database password
- JWT secret
- API keys
- Sentry DSN if treated as secret in your deployment flow

### 4. deployment.yaml

Defines:

- number of replicas
- container image
- readiness/liveness probes
- resource requests/limits
- environment variables
- ports

### 5. service.yaml

Exposes the backend inside the cluster.

Use `ClusterIP` for internal traffic and `LoadBalancer` or `Ingress` for public traffic.

### 6. ingress.yaml

Routes external traffic to the backend.

Typical use cases:

- `/api`
- `/health`
- `/metrics`

### 7. hpa.yaml

Auto-scales pods based on CPU or memory.

Example:

- min replicas: 2
- max replicas: 5
- CPU target: 70%

---

## What to monitor in Kubernetes

### Backend metrics

The backend should expose `/metrics` and `/health`.

Metrics to scrape:

- `http_requests_total`
- `http_request_duration_seconds`
- `process_resident_memory_bytes`
- `process_cpu_seconds_total`

### Pod health

Use probes:

- `readinessProbe` on `/health`
- `livenessProbe` on `/health`

### Scaling signals

Use HPA with:

- CPU usage
- memory usage
- optionally custom metrics if exposed

---

## Where the frontend fits

If you want to deploy Flutter web with Kubernetes:

- build the app as static web assets
- serve with Nginx in a container
- expose it with a separate Ingress route
- keep it independent from backend scaling

In most cases, the frontend does not need the same Kubernetes setup as the backend.

---

## Recommended deployment order

1. backend API
2. database or external managed database
3. observability stack
4. ingress and DNS
5. frontend web, if needed

---

## Minimal backend manifest example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: my-backend:latest
          ports:
            - containerPort: 3000
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
```

---

## Minimal service example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: my-app
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 3000
```

---

## Minimal ingress example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  namespace: my-app
spec:
  rules:
    - host: api.myapp.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 80
```

---

## Monitoring integration with this project

Your current observability setup already gives you the monitoring side:

- Grafana dashboards
- Prometheus scraping
- Alertmanager routing
- Loki logs

So the Kubernetes part should mainly host:

- backend application pods
- observability stack pods if you want to migrate from Docker Compose

---

## Practical recommendation for this repo

Because this repository is Flutter-focused:

- keep Kubernetes documentation here
- put backend K8s manifests in the backend repo
- put Flutter web deployment manifests here only if you plan to host the web build in Kubernetes

---

## Next step

If you want, the next useful move is to create a `k8s/` folder with backend manifest templates and a separate `k8s/observability/` folder for Prometheus/Grafana/Alertmanager/Loki.
