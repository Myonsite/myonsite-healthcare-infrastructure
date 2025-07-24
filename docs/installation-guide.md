# Installation Guide

## 🎯 Overview

This guide provides step-by-step instructions for installing and configuring the MedinovAI AI-Managed Kubernetes Infrastructure. The installation process sets up a complete AI-operated development environment with CrewAI multi-agent orchestration, Istio service mesh, and Backstage developer portal.

## 📋 Prerequisites

### System Requirements

#### Hardware Requirements
- **CPU**: Minimum 8 cores, recommended 16+ cores
- **RAM**: Minimum 16GB, recommended 32GB+
- **Storage**: Minimum 100GB free space, recommended 500GB+
- **Network**: Stable internet connection for downloads and updates

#### Software Requirements
- **Operating System**: macOS 12+, Ubuntu 20.04+, or Windows 11+
- **Docker**: Version 24.0.0 or higher
- **kind**: Version 0.23.0 or higher
- **kubectl**: Version 1.30.0 or higher
- **helm**: Version 3.16.0 or higher
- **GNU Make**: Version 4.0 or higher

### Development Tools
- **Git**: Version 2.30.0 or higher
- **Python**: Version 3.11 or higher (for CrewAI)
- **Node.js**: Version 18.0.0 or higher (for Backstage)
- **jq**: JSON processor for script automation

## 🚀 Quick Installation

### Automated Installation

#### One-Command Installation
```bash
# Clone the repository
git clone https://github.com/medinovai/docker-maintenance.git
cd docker-maintenance

# Run automated installation
make install-all
```

#### What the Automated Installation Does
1. **Prerequisites Check**: Validates all required software and hardware
2. **Environment Setup**: Configures development environment
3. **Kubernetes Cluster**: Creates local Kubernetes cluster using kind
4. **Core Services**: Installs Istio, Backstage, and monitoring stack
5. **CrewAI Platform**: Deploys CrewAI multi-agent orchestration platform
6. **Configuration**: Applies all necessary configurations and policies
7. **Validation**: Runs comprehensive validation tests

### Manual Installation

#### Step 1: Prerequisites Installation

##### macOS Installation
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install docker kind kubectl helm make git python@3.11 node jq

# Start Docker Desktop
open -a Docker
```

##### Ubuntu Installation
```bash
# Update package list
sudo apt update

# Install required packages
sudo apt install -y docker.io kind kubectl helm make git python3.11 nodejs npm jq

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

##### Windows Installation
```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install docker-desktop kind kubernetes-cli kubernetes-helm make git python nodejs jq

# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### Step 2: Repository Setup
```bash
# Clone the repository
git clone https://github.com/medinovai/docker-maintenance.git
cd docker-maintenance

# Verify prerequisites
make check-prereqs
```

#### Step 3: Kubernetes Cluster Setup
```bash
# Create local Kubernetes cluster
make dev-up

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

#### Step 4: Core Infrastructure Deployment
```bash
# Deploy Istio service mesh
make mesh-install
make mesh-up

# Deploy Backstage developer portal
make deploy-simple

# Verify deployments
make status
```

#### Step 5: CrewAI Platform Deployment
```bash
# Deploy CrewAI multi-agent platform
make crewai-install

# Verify CrewAI deployment
make crewai-status
```

#### Step 6: Configuration and Validation
```bash
# Apply security policies
kubectl apply -f infra/security/

# Apply compliance policies
kubectl apply -f infra/compliance/

# Run validation tests
make validate-all
```

## 🔧 Detailed Configuration

### Environment Configuration

#### Environment Variables
```bash
# Create environment configuration file
cat > .env << EOF
# Cluster Configuration
CLUSTER_NAME=medinovai-local
KUBERNETES_VERSION=v1.33.3
ISTIO_VERSION=1.24.1

# CrewAI Configuration
CREWAI_API_HOST=0.0.0.0
CREWAI_API_PORT=8000
CREWAI_DATABASE_HOST=crewai-postgresql
CREWAI_DATABASE_PORT=5432
CREWAI_DATABASE_NAME=crewai

# Backstage Configuration
BACKSTAGE_PORT=3001
BACKSTAGE_DATABASE_HOST=backstage-postgresql
BACKSTAGE_DATABASE_PORT=5432

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
JAEGER_PORT=16686
KIALI_PORT=20001

# Security Configuration
MTLS_MODE=STRICT
AUTHORIZATION_POLICY=ENABLED
AUDIT_LOGGING=ENABLED
EOF
```

#### Kubernetes Configuration
```bash
# Create Kubernetes configuration
cat > infra/k8s-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: medinovai-config
  namespace: infrastructure
data:
  cluster-name: "medinovai-local"
  environment: "development"
  monitoring-enabled: "true"
  security-enabled: "true"
  compliance-enabled: "true"
EOF

# Apply configuration
kubectl apply -f infra/k8s-config.yaml
```

### Security Configuration

#### Istio Security Policies
```bash
# Create Istio security policies
cat > infra/istio/security/authorization-policy.yaml << EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: default-deny
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/default"]
    to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
        paths: ["/api/*"]
EOF

# Apply security policies
kubectl apply -f infra/istio/security/
```

#### Network Policies
```bash
# Create network policies
cat > infra/network-policies/default-deny.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Apply network policies
kubectl apply -f infra/network-policies/
```

### Compliance Configuration

#### Compliance Policies
```bash
# Create compliance policies
cat > infra/compliance/policies.yaml << EOF
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: compliance-audit
  namespace: istio-system
spec:
  match: destination.labels["app"] == "crewai-app"
  actions:
  - handler: compliance.handler
    instances:
    - audit.instance
EOF

# Apply compliance policies
kubectl apply -f infra/compliance/
```

#### Audit Configuration
```bash
# Create audit configuration
cat > infra/audit/audit-policy.yaml << EOF
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods", "services", "configmaps", "secrets"]
- level: Metadata
  resources:
  - group: ""
    resources: ["namespaces", "nodes"]
EOF

# Apply audit configuration
kubectl apply -f infra/audit/
```

## 📊 Monitoring Setup

### Prometheus Configuration

#### Prometheus Rules
```bash
# Create Prometheus rules
cat > infra/monitoring/prometheus-rules.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: medinovai-alerts
  namespace: monitoring
spec:
  groups:
  - name: medinovai
    rules:
    - alert: HighCPUUsage
      expr: container_cpu_usage_seconds_total > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: High CPU usage detected
        description: Container {{ $labels.container }} has high CPU usage
EOF

# Apply Prometheus rules
kubectl apply -f infra/monitoring/
```

#### Grafana Dashboards
```bash
# Create Grafana dashboards
cat > infra/monitoring/grafana-dashboards/medinovai-overview.json << EOF
{
  "dashboard": {
    "title": "MedinovAI Overview",
    "panels": [
      {
        "title": "System Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up",
            "legendFormat": "{{job}}"
          }
        ]
      }
    ]
  }
}
EOF

# Apply Grafana dashboards
kubectl apply -f infra/monitoring/grafana-dashboards/
```

### Logging Configuration

#### Loki Configuration
```bash
# Create Loki configuration
cat > infra/logging/loki-config.yaml << EOF
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOF

# Apply Loki configuration
kubectl apply -f infra/logging/
```

## 🔐 Security Setup

### Certificate Management

#### mTLS Certificates
```bash
# Create certificate authority
cat > infra/certificates/ca-config.yaml << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

# Create certificates
cat > infra/certificates/certificates.yaml << EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: medinovai-cert
  namespace: istio-system
spec:
  secretName: medinovai-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  dnsNames:
  - medinovai.local
  - *.medinovai.local
EOF

# Apply certificates
kubectl apply -f infra/certificates/
```

#### Secret Management
```bash
# Create secrets
cat > infra/secrets/medinovai-secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: medinovai-secrets
  namespace: infrastructure
type: Opaque
data:
  # Base64 encoded secrets
  database-password: Y3Jld2FpX3Bhc3N3b3Jk
  api-key: c2stZXhhbXBsZQ==
  jwt-secret: c2VjcmV0LWtleQ==
EOF

# Apply secrets
kubectl apply -f infra/secrets/
```

### Access Control

#### RBAC Configuration
```bash
# Create RBAC roles
cat > infra/rbac/roles.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: medinovai-admin
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# Create RBAC bindings
cat > infra/rbac/bindings.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: medinovai-admin-binding
subjects:
- kind: ServiceAccount
  name: medinovai-admin
  namespace: infrastructure
roleRef:
  kind: ClusterRole
  name: medinovai-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# Apply RBAC configuration
kubectl apply -f infra/rbac/
```

## 🧪 Validation and Testing

### Health Checks

#### System Health Validation
```bash
# Run comprehensive health checks
make health-check

# Check all components
kubectl get pods -A
kubectl get services -A
kubectl get ingress -A
```

#### Service Validation
```bash
# Test Istio service mesh
make mesh-test

# Test CrewAI platform
make crewai-test

# Test Backstage portal
make portal-test
```

### Performance Testing

#### Load Testing
```bash
# Run load tests
make load-test

# Monitor performance
kubectl top pods -A
kubectl top nodes
```

#### Stress Testing
```bash
# Run stress tests
make stress-test

# Monitor system resources
kubectl describe nodes
```

### Security Testing

#### Security Scanning
```bash
# Run security scans
make security-scan

# Check for vulnerabilities
kubectl get securitycontextconstraints
```

#### Compliance Testing
```bash
# Run compliance tests
make compliance-test

# Generate compliance report
make compliance-report
```

## 🔧 Troubleshooting

### Common Issues

#### Cluster Issues
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# Reset cluster if needed
make dev-down
make dev-up
```

#### Pod Issues
```bash
# Check pod status
kubectl get pods -A
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name> -n <namespace>
```

#### Service Issues
```bash
# Check service status
kubectl get services -A
kubectl describe service <service-name>

# Test service connectivity
kubectl exec -it <pod-name> -- curl <service-url>
```

#### Network Issues
```bash
# Check network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name>

# Test network connectivity
kubectl exec -it <pod-name> -- ping <target>
```

### Debugging Tools

#### Debugging Commands
```bash
# Get detailed information
kubectl get all -A -o wide
kubectl describe all -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -A
kubectl top nodes
```

#### Log Analysis
```bash
# Collect logs
kubectl logs -l app=crewai-app -n crewai
kubectl logs -l app=backstage -n infrastructure

# Analyze logs
kubectl logs -l app=crewai-app -n crewai | grep ERROR
kubectl logs -l app=backstage -n infrastructure | grep WARN
```

## 📚 Post-Installation

### Access Information

#### Service URLs
- **Backstage Portal**: http://localhost:3001
- **CrewAI API**: http://localhost:8000
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Kiali**: http://localhost:20001
- **Jaeger**: http://localhost:16686

#### Default Credentials
- **Backstage**: admin/admin
- **Grafana**: admin/admin
- **CrewAI**: No authentication required (development mode)

### Next Steps

#### Configuration
1. **Update Secrets**: Replace default secrets with production values
2. **Configure Monitoring**: Set up alerting and notification channels
3. **Set Up Backup**: Configure backup and disaster recovery
4. **Security Hardening**: Apply additional security measures

#### Development
1. **Create Projects**: Set up development projects in Backstage
2. **Configure Agents**: Set up AI agents for your development workflow
3. **Define Policies**: Create development policies and standards
4. **Set Up CI/CD**: Configure continuous integration and deployment

#### Operations
1. **Monitoring Setup**: Configure monitoring and alerting
2. **Logging Setup**: Set up centralized logging and analysis
3. **Backup Setup**: Configure automated backup procedures
4. **Documentation**: Create operational documentation and runbooks

## 🔄 Maintenance

### Regular Maintenance

#### Updates
```bash
# Update components
make update-all

# Update specific components
make update-istio
make update-crewai
make update-backstage
```

#### Backups
```bash
# Create backups
make backup-all

# Restore from backup
make restore-backup
```

#### Health Monitoring
```bash
# Monitor system health
make health-monitor

# Generate health report
make health-report
```

### Troubleshooting Resources

#### Documentation
- **Architecture Overview**: [docs/architecture-overview.md](architecture-overview.md)
- **Troubleshooting Guide**: [docs/troubleshooting-guide.md](troubleshooting-guide.md)
- **API Reference**: [docs/api-reference.md](api-reference.md)

#### Support
- **GitHub Issues**: Report issues on GitHub
- **Documentation**: Check comprehensive documentation
- **Community**: Join community discussions

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Maintainer**: MedinovAI Infrastructure Team 