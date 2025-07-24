# MedinovAI Service Mesh Operator Guide
**Version**: 1.0  
**Date**: July 2025  
**Classification**: Internal Use Only  
**Compliance**: ISO/IEC 26514, HIPAA, ISO 27001/27002

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Operations](#operations)
6. [Security](#security)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)
9. [Compliance](#compliance)

## 1. Overview

### 1.1 Purpose
This guide provides comprehensive instructions for operating the Istio-based service mesh that secures all MedinovAI microservices with zero-trust networking, mTLS encryption, and HIPAA-compliant audit logging.

### 1.2 Scope
- Local development on macOS (M4 MacBook Pro, Mac minis)
- Single-node Kubernetes clusters (KinD/k3d)
- Istio 1.24.1+ with sidecar or ambient mode
- All MedinovAI AI agents and microservices

### 1.3 Key Features
- **Automatic mTLS**: All service-to-service communication encrypted
- **RBAC**: Fine-grained access control with JWT validation
- **Audit Logging**: HIPAA-compliant JSON logs with full traceability
- **Observability**: Prometheus, Grafana, Kiali, Jaeger integration
- **Zero-Trust**: Deny-by-default with explicit authorization policies

## 2. Architecture

### 2.1 Components
```
┌─────────────────────────────────────────────────────────────┐
│                    Istio Control Plane                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐  │
│  │  Pilot  │  │ Citadel │  │ Galley  │  │ Telemetry   │  │
│  │  (xDS)  │  │  (CA)   │  │(Config) │  │(Prometheus) │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                     Data Plane (Envoy Proxies)            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ Audit Agent │  │Discovery    │  │ Diagnosis   │      │
│  │   + Envoy   │  │Agent+Envoy  │  │Agent+Envoy  │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │Billing Agent│  │Whisper Agent│  │ LangServe   │      │
│  │   + Envoy   │  │   + Envoy   │  │   + Envoy   │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
└───────────────────────────────────────────────────────────┘
```

### 2.2 Traffic Flow
1. All traffic enters through Envoy sidecar proxy
2. mTLS handshake validates service identity
3. Authorization policies check JWT claims and service accounts
4. Telemetry logs all requests with security context
5. Traffic forwarded to application container

## 3. Installation

### 3.1 Prerequisites
```bash
# Verify prerequisites
docker --version  # Docker Desktop 4.30+
kubectl version   # kubectl 1.31+
kind --version    # kind 0.20+
```

### 3.2 Quick Start
```bash
# 1. Create Kubernetes cluster
make dev-up

# 2. Install Istio
make mesh-install

# 3. Deploy mesh configuration
make mesh-up

# 4. Verify installation
make mesh-status
```

### 3.3 Manual Installation
```bash
# Install specific Istio version
ISTIO_VERSION=1.24.1 ./infra/istio/install.sh

# Enable ambient mode (optional)
INSTALL_MODE=ambient ./infra/istio/install.sh
```

## 4. Configuration

### 4.1 mTLS Configuration
All services use STRICT mTLS by default:
```yaml
# infra/istio/base/strict-mtls.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

### 4.2 Service Accounts
Each service requires a dedicated service account:
```bash
# Applied automatically via:
kubectl apply -f infra/istio/medinovai/service-accounts.yaml
```

### 4.3 Authorization Policies
RBAC policies enforce least-privilege access:
```bash
# Applied automatically via:
kubectl apply -f infra/istio/medinovai/authorization-policies.yaml
```

### 4.4 Namespace Labels
Enable automatic sidecar injection:
```bash
kubectl label namespace infrastructure istio-injection=enabled
kubectl label namespace default istio-injection=enabled
```

## 5. Operations

### 5.1 Daily Operations

#### Check Mesh Health
```bash
# Overall status
make mesh-status

# Detailed proxy status
istioctl proxy-status

# Check mTLS
istioctl authn tls-check
```

#### View Dashboards
```bash
# Open all dashboards
make mesh-dashboard

# Individual dashboards
kubectl -n istio-system port-forward svc/kiali 20001:20001
kubectl -n istio-system port-forward svc/grafana 3000:3000
```

### 5.2 Service Deployment

#### Deploy New Service
1. Create service account in `service-accounts.yaml`
2. Add authorization policy in `authorization-policies.yaml`
3. Ensure pod spec includes:
```yaml
spec:
  serviceAccountName: <service-name>
  containers:
  - name: <service-name>
    # ... container spec
```

#### Update Existing Service
```bash
# Restart pods to pick up new sidecar
kubectl rollout restart deployment/<service-name> -n infrastructure
```

### 5.3 Certificate Management
Istio automatically rotates certificates every 90 days. Monitor with:
```bash
# Check certificate expiry
istioctl proxy-config secret <pod-name> -n infrastructure | grep VALID
```

## 6. Security

### 6.1 Zero-Trust Principles
- **Default Deny**: No traffic allowed without explicit policy
- **Service Identity**: Every service has unique SPIFFE identity
- **Mutual Authentication**: Both client and server verify identity
- **Encrypted Transport**: TLS 1.3 for all communications

### 6.2 JWT Validation
For user-facing services:
```yaml
when:
- key: request.auth.claims[role]
  values: ["doctor", "nurse"]
- key: request.auth.claims[scope]
  values: ["patient:read", "diagnosis:write"]
```

### 6.3 Security Exceptions
Document any exceptions:
```yaml
# SECURITY_EXCEPTION: GPU workload requires host networking
sidecar.istio.io/inject: "false"
```

## 7. Monitoring

### 7.1 Key Metrics

#### mTLS Coverage
```promql
(sum(rate(istio_request_total{security_policy="mutual_tls"}[5m])) / 
 sum(rate(istio_request_total[5m]))) * 100
```

#### Authorization Denials
```promql
sum(increase(istio_request_total{response_code="403"}[1h]))
```

#### Service Latency
```promql
histogram_quantile(0.99, 
  sum(rate(istio_request_duration_milliseconds_bucket[5m])) 
  by (destination_service_name, le))
```

### 7.2 Alerts
Configure alerts for:
- mTLS coverage < 100%
- Authorization denial rate > threshold
- Certificate expiry < 7 days
- Proxy out of sync

### 7.3 Audit Logs
Access logs in JSON format:
```bash
# View logs for specific service
kubectl logs -n infrastructure <pod-name> -c istio-proxy | jq .

# Export logs for compliance
kubectl logs -n infrastructure -l app=<service> -c istio-proxy > /reports/envoy/audit-$(date +%Y%m%d).json
```

## 8. Troubleshooting

### 8.1 Common Issues

#### Service Cannot Connect
```bash
# Check authorization policies
istioctl analyze -n infrastructure

# View proxy configuration
istioctl proxy-config listeners <pod-name> -n infrastructure

# Check logs
kubectl logs <pod-name> -n infrastructure -c istio-proxy
```

#### High Latency
```bash
# Check proxy CPU/memory
kubectl top pods -n infrastructure

# Adjust resources if needed
kubectl edit deployment <service-name> -n infrastructure
```

#### Certificate Issues
```bash
# Force certificate refresh
kubectl delete secret istio-ca-secret -n istio-system
kubectl rollout restart deployment/istiod -n istio-system
```

### 8.2 Debug Mode
Enable debug logging:
```bash
istioctl proxy-config log <pod-name> -n infrastructure --level debug
```

### 8.3 Bypass Mesh (Emergency Only)
```yaml
# Add annotation to pod
sidecar.istio.io/inject: "false"  # SECURITY_EXCEPTION: Emergency bypass
```

## 9. Compliance

### 9.1 HIPAA Requirements

#### Encryption in Transit (164.312(e)(1))
- ✅ All traffic encrypted with mTLS
- ✅ TLS 1.3 minimum
- ✅ Strong cipher suites only

#### Access Control (164.312(a)(1))
- ✅ Service-level RBAC
- ✅ JWT validation for user access
- ✅ Audit trail of all access

#### Audit Controls (164.312(b))
- ✅ All requests logged with security context
- ✅ 7-day retention minimum
- ✅ Tamper-proof JSON format

### 9.2 ISO 27001/27002 Controls

#### A.9 Access Control
- Service accounts for all components
- Least-privilege authorization policies
- Regular access reviews

#### A.12.4 Logging and Monitoring
- Centralized logging via Envoy
- Real-time security dashboards
- Automated compliance reports

#### A.13 Communications Security
- Network segmentation via namespaces
- Encrypted communications (mTLS)
- Traffic authorization policies

### 9.3 Compliance Validation
```bash
# Run compliance tests
make mesh-test

# Generate compliance report
./infra/istio/compliance-report.sh > /reports/compliance-$(date +%Y%m%d).pdf
```

### 9.4 Audit Checklist
- [ ] All services have mTLS enabled
- [ ] No PERMISSIVE mode policies
- [ ] Authorization policies reviewed quarterly
- [ ] Certificates valid > 30 days
- [ ] Audit logs archived after 7 days
- [ ] Dashboards monitored daily
- [ ] Compliance reports generated monthly

---

**Document Control**
- **Author**: MedinovAI DevOps Team
- **Review**: Security Team, Compliance Officer
- **Next Review**: Quarterly
- **Distribution**: Engineering, Security, Compliance 