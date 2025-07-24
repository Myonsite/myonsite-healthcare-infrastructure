# MedinovAI Service Mesh Quick Start
**Get your service mesh-ready in < 10 minutes**

## 🚀 One-Command Setup
```bash
# Complete mesh setup
make dev-up && make mesh-install && make mesh-up
```

## 📋 Pre-Flight Check
```bash
# Ensure Docker Desktop is running
docker info | grep "Server Version"

# Check available resources
docker system df
```

## 🔧 Essential Commands

### Start Everything
```bash
make dev-up          # Create cluster
make mesh-install    # Install Istio
make mesh-up         # Deploy configs
make portal          # Access portal
```

### Check Status
```bash
make mesh-status     # Health check
make mesh-dashboard  # Open dashboards
```

### Clean Up
```bash
make mesh-down       # Remove Istio
make dev-down        # Delete cluster
```

## 🎯 Deploy Your Service

### 1. Create Service Account
Add to `infra/istio/medinovai/service-accounts.yaml`:
```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service
  namespace: infrastructure
  labels:
    app: my-service
```

### 2. Add Authorization Policy
Add to `infra/istio/medinovai/authorization-policies.yaml`:
```yaml
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-service-policy
  namespace: infrastructure
spec:
  selector:
    matchLabels:
      app: my-service
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/infrastructure/sa/backstage"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/my-service/*"]
```

### 3. Deploy with Sidecar
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
  namespace: infrastructure
spec:
  selector:
    matchLabels:
      app: my-service
  template:
    metadata:
      labels:
        app: my-service
    spec:
      serviceAccountName: my-service  # Required!
      containers:
      - name: my-service
        image: myservice:latest
        ports:
        - containerPort: 8080
```

### 4. Apply Changes
```bash
kubectl apply -f my-service-deployment.yaml
kubectl rollout status deployment/my-service -n infrastructure
```

## 🔍 Verify mTLS
```bash
# Check your service has mTLS
istioctl authn tls-check my-service.infrastructure.svc.cluster.local

# Expected output:
# HOST:PORT                                    STATUS       CLIENT     AUTHN POLICY     DESTINATION RULE
# my-service.infrastructure.svc.cluster.local:8080  OK      STRICT     default/         -
```

## 📊 Monitor Your Service

### Kiali (Service Graph)
```bash
kubectl -n istio-system port-forward svc/kiali 20001:20001
# Open http://localhost:20001
```

### Grafana (Metrics)
```bash
kubectl -n istio-system port-forward svc/grafana 3000:3000
# Open http://localhost:3000
# Dashboard: "HIPAA Compliance - Service Mesh"
```

### View Logs
```bash
# Your app logs
kubectl logs -n infrastructure deployment/my-service

# Envoy proxy logs (mTLS info)
kubectl logs -n infrastructure deployment/my-service -c istio-proxy
```

## 🚨 Common Issues

### Service Can't Connect
```bash
# Check policies
istioctl analyze -n infrastructure

# Debug authorization
kubectl logs -n infrastructure deployment/my-service -c istio-proxy | grep "RBAC"
```

### High Latency
```bash
# Check proxy resources
kubectl top pods -n infrastructure -l app=my-service

# Increase if needed (add to deployment):
# resources:
#   requests:
#     cpu: 100m
#     memory: 128Mi
```

### No Sidecar Injected
```bash
# Check namespace label
kubectl get ns infrastructure -o yaml | grep istio-injection

# Should show: istio-injection: enabled
```

## 🔐 Security Checklist
- ✅ Service account created
- ✅ Authorization policy defined  
- ✅ mTLS verified (istioctl authn tls-check)
- ✅ No plaintext traffic (check Kiali)
- ✅ Logs show connection_security_policy: "mutual_tls"

## 📚 Next Steps
1. Read full [Operator Guide](service-mesh-operator-guide.md)
2. Explore [Authorization Policies](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
3. Configure [JWT validation](https://istio.io/latest/docs/tasks/security/authorization/authz-jwt/)
4. Set up [Distributed Tracing](https://istio.io/latest/docs/tasks/observability/distributed-tracing/)

---
**Need Help?** 
- Slack: #medinovai-mesh
- Wiki: https://wiki.medinovai.com/service-mesh
- On-call: mesh-oncall@medinovai.com 