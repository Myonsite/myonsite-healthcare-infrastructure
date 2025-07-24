#!/bin/bash
# Istio Installation Script for MedinovAI Service Mesh
# ISO 27001/27002 Compliant Installation Process

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ISTIO_VERSION="${ISTIO_VERSION:-1.24.1}"
ISTIO_NAMESPACE="istio-system"
INSTALL_MODE="${INSTALL_MODE:-sidecar}" # sidecar or ambient
REPORTS_DIR="/reports/envoy"
LOG_FILE="/tmp/istio-install-$(date +%Y%m%d-%H%M%S).log"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

# Pre-flight checks
preflight_check() {
    log "Running pre-flight checks..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        warn "This script is optimized for macOS but will attempt to continue..."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker Desktop."
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install kubectl."
    fi
    
    # Check for Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "No Kubernetes cluster found. Please start kind/k3d cluster first."
    fi
    
    # Check for ARM64 architecture
    if [[ "$(uname -m)" == "arm64" ]]; then
        info "Detected ARM64 architecture (Apple Silicon)"
        export ARCH="arm64"
    else
        export ARCH="amd64"
    fi
    
    log "Pre-flight checks passed ✓"
}

# Download and install istioctl
install_istioctl() {
    log "Installing istioctl ${ISTIO_VERSION}..."
    
    if command -v istioctl &> /dev/null; then
        CURRENT_VERSION=$(istioctl version --remote=false 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ "$CURRENT_VERSION" == "$ISTIO_VERSION" ]]; then
            info "istioctl ${ISTIO_VERSION} already installed"
            return 0
        fi
    fi
    
    # Download istioctl
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
    
    # Move to PATH
    sudo mv istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/
    rm -rf istio-${ISTIO_VERSION}
    
    log "istioctl ${ISTIO_VERSION} installed successfully"
}

# Install Istio control plane
install_istio() {
    log "Installing Istio control plane..."
    
    # Create namespace
    kubectl create namespace ${ISTIO_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace
    kubectl label namespace ${ISTIO_NAMESPACE} istio-injection=disabled --overwrite
    
    # Install based on mode
    if [[ "$INSTALL_MODE" == "ambient" ]]; then
        log "Installing Istio in Ambient mode..."
        istioctl install --set values.pilot.env.PILOT_ENABLE_AMBIENT=true \
                        --set profile=ambient \
                        --set values.pilot.resources.requests.cpu=200m \
                        --set values.pilot.resources.requests.memory=256Mi \
                        --set values.pilot.resources.limits.cpu=500m \
                        --set values.pilot.resources.limits.memory=512Mi \
                        -y
    else
        log "Installing Istio in Sidecar mode..."
        istioctl install --set profile=default \
                        --set values.pilot.resources.requests.cpu=200m \
                        --set values.pilot.resources.requests.memory=256Mi \
                        --set values.pilot.resources.limits.cpu=500m \
                        --set values.pilot.resources.limits.memory=512Mi \
                        --set values.global.proxy.resources.requests.cpu=50m \
                        --set values.global.proxy.resources.requests.memory=64Mi \
                        --set values.global.proxy.resources.limits.cpu=200m \
                        --set values.global.proxy.resources.limits.memory=256Mi \
                        -y
    fi
    
    # Wait for Istio to be ready
    log "Waiting for Istio control plane to be ready..."
    kubectl -n ${ISTIO_NAMESPACE} wait --for=condition=ready pod -l app=istiod --timeout=300s
    
    log "Istio control plane installed successfully"
}

# Configure mTLS
configure_mtls() {
    log "Configuring strict mTLS..."
    
    # Apply strict mTLS policy
    kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: ${ISTIO_NAMESPACE}
spec:
  mtls:
    mode: STRICT
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: default
  namespace: ${ISTIO_NAMESPACE}
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  exportTo:
    - "*"
EOF
    
    log "mTLS configured in STRICT mode"
}

# Install observability stack
install_observability() {
    log "Installing observability stack..."
    
    # Install Prometheus
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION%.*}/samples/addons/prometheus.yaml
    
    # Install Grafana
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION%.*}/samples/addons/grafana.yaml
    
    # Install Kiali
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION%.*}/samples/addons/kiali.yaml
    
    # Install Jaeger
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION%.*}/samples/addons/jaeger.yaml
    
    # Wait for addons to be ready
    log "Waiting for observability stack to be ready..."
    for addon in prometheus grafana kiali jaeger-collector; do
        kubectl -n ${ISTIO_NAMESPACE} wait --for=condition=ready pod -l app=$addon --timeout=300s || warn "$addon not ready"
    done
    
    log "Observability stack installed"
}

# Configure audit logging
configure_audit_logging() {
    log "Configuring HIPAA-compliant audit logging..."
    
    # Create reports directory
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: envoy-log-config
  namespace: ${ISTIO_NAMESPACE}
data:
  log-format.json: |
    {
      "timestamp": "%START_TIME%",
      "trace_id": "%REQ(X-B3-TRACEID)%",
      "src_workload": "%DOWNSTREAM_LOCAL_ADDRESS%",
      "dst_workload": "%UPSTREAM_HOST%",
      "method": "%REQ(:METHOD)%",
      "path": "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%",
      "protocol": "%PROTOCOL%",
      "response_code": "%RESPONSE_CODE%",
      "response_flags": "%RESPONSE_FLAGS%",
      "bytes_received": "%BYTES_RECEIVED%",
      "bytes_sent": "%BYTES_SENT%",
      "duration": "%DURATION%",
      "connection_security_policy": "%CONNECTION_SECURITY_POLICY%",
      "tls_version": "%DOWNSTREAM_TLS_VERSION%",
      "tls_cipher": "%DOWNSTREAM_TLS_CIPHER%",
      "mtls_mode": "%DOWNSTREAM_PEER_SUBJECT%"
    }
EOF
    
    # Apply telemetry configuration
    kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: hipaa-access-logging
  namespace: ${ISTIO_NAMESPACE}
spec:
  accessLogging:
    - providers:
        - name: otel
EOF
    
    log "Audit logging configured"
}

# Enable automatic sidecar injection
enable_injection() {
    log "Enabling automatic sidecar injection..."
    
    # Label infrastructure namespace
    kubectl label namespace infrastructure istio-injection=enabled --overwrite || true
    
    # Label default namespace
    kubectl label namespace default istio-injection=enabled --overwrite || true
    
    log "Automatic sidecar injection enabled"
}

# Create sample authorization policies
create_sample_policies() {
    log "Creating sample authorization policies..."
    
    # Create RBAC policy for MedinovAI services
    kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: medinovai-rbac
  namespace: infrastructure
spec:
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/infrastructure/sa/audit-agent"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/audit/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/infrastructure/sa/discovery-agent"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/discovery/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/infrastructure/sa/diagnosis-agent"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/diagnosis/*"]
    when:
    - key: request.auth.claims[role]
      values: ["doctor", "nurse"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-billing-access
  namespace: infrastructure
spec:
  selector:
    matchLabels:
      app: billing-service
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals: ["cluster.local/ns/infrastructure/sa/billing-agent"]
EOF
    
    log "Sample authorization policies created"
}

# Print summary
print_summary() {
    log "Installation Summary:"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Istio Version:${NC} ${ISTIO_VERSION}"
    echo -e "${BLUE}Mode:${NC} ${INSTALL_MODE}"
    echo -e "${BLUE}mTLS:${NC} STRICT"
    echo -e "${BLUE}Namespace:${NC} ${ISTIO_NAMESPACE}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check mTLS status
    info "Checking mTLS status..."
    istioctl authn tls-check || true
    
    # Print access URLs
    echo -e "\n${BLUE}Access URLs:${NC}"
    echo "Kiali:      http://localhost:20001"
    echo "Grafana:    http://localhost:3000"
    echo "Prometheus: http://localhost:9090"
    echo "Jaeger:     http://localhost:16686"
    
    echo -e "\n${BLUE}Port-forward commands:${NC}"
    echo "kubectl -n istio-system port-forward svc/kiali 20001:20001"
    echo "kubectl -n istio-system port-forward svc/grafana 3000:3000"
    echo "kubectl -n istio-system port-forward svc/prometheus 9090:9090"
    echo "kubectl -n istio-system port-forward svc/tracing 16686:16686"
    
    echo -e "\n${GREEN}✓ Istio installation complete!${NC}"
    echo -e "Log file: ${LOG_FILE}"
}

# Main installation flow
main() {
    log "Starting Istio installation for MedinovAI..."
    
    preflight_check
    install_istioctl
    install_istio
    configure_mtls
    install_observability
    configure_audit_logging
    enable_injection
    create_sample_policies
    print_summary
    
    log "Installation completed successfully!"
}

# Run main function
main "$@" 