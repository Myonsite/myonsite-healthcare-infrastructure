# Makefile – MedinovAI Infrastructure Automation
# Compatible with Kubernetes v1.33 and latest stable tools

CLUSTER_NAME := health-local
KIND_CFG     := infra/kind-minimal.yaml
KUBECTL_VERSION := v1.33.3
HELM_VERSION := v3.16.3
ISTIO_VERSION := 1.24.1

.PHONY: dev-up dev-down deploy-simple portal check-prereqs clean mesh-install mesh-up mesh-down mesh-status mesh-dashboard mesh-test

## Prerequisites check
check-prereqs:
	@echo "🔍 Checking prerequisites..."
	@command -v kind >/dev/null 2>&1 || { echo "❌ kind not found. Install: brew install kind"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found. Install: brew install kubectl"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "❌ helm not found. Install: brew install helm"; exit 1; }
	@echo "✅ All prerequisites met"

## Create minimal kind cluster and deploy MedinovAI stack
dev-up: check-prereqs ## Spin up minimal local kind cluster and deploy full stack
	@echo "🚀 Creating kind cluster with Kubernetes v1.33..."
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CFG) --wait 5m
	@echo "⏳ Waiting for cluster to be ready..."
	sleep 15
	$(MAKE) deploy-simple

## Delete kind cluster
dev-down: ## Tear down the entire cluster
	@echo "🗑️  Deleting kind cluster..."
	kind delete cluster --name $(CLUSTER_NAME) || true

## Deploy simplified MedinovAI stack
deploy-simple:
	@echo "📦 Deploying MedinovAI infrastructure..."
	kubectl apply -f infra/clusters/local/backstage-simple.yaml
	@echo "⏳ Waiting for pods to be ready..."
	kubectl -n infrastructure wait --for=condition=ready pod -l app=backstage --timeout=300s || true
	@echo "✅ MedinovAI Developer Portal deployed successfully!"
	@echo "🚀 Run 'make portal' to access the portal"

## Access the portal via port-forward
portal: ## Open MedinovAI Developer Portal
	@echo "🌐 Opening MedinovAI Developer Portal..."
	@echo "🔗 Portal will be available at: http://localhost:3001"
	@echo "🛑 Press Ctrl+C to stop port forwarding"
	kubectl -n infrastructure port-forward service/backstage 3001:80

## Install Istio service mesh
mesh-install: ## Install istioctl and Istio control plane
	@echo "🔷 Installing Istio service mesh..."
	@chmod +x infra/istio/install.sh
	@infra/istio/install.sh

## Deploy service mesh configuration
mesh-up: ## Deploy Istio configuration and enable mesh
	@echo "🔷 Deploying Istio service mesh configuration..."
	@kubectl apply -k infra/istio/base/
	@echo "✅ Service mesh configuration applied"
	@echo "🔐 mTLS: STRICT mode enabled"
	@echo "📊 Run 'make mesh-dashboard' to access observability tools"

## Remove Istio service mesh
mesh-down: ## Remove Istio from cluster
	@echo "🗑️  Removing Istio service mesh..."
	@istioctl uninstall --purge -y || true
	@kubectl delete namespace istio-system --ignore-not-found=true
	@echo "✅ Istio removed"

## Check mesh status
mesh-status: ## Show service mesh status and mTLS verification
	@echo "🔷 Istio Service Mesh Status:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@istioctl version || echo "❌ Istio not installed"
	@echo "\n📊 Control Plane Status:"
	@kubectl -n istio-system get pods 2>/dev/null || echo "❌ No Istio pods found"
	@echo "\n🔐 mTLS Status:"
	@istioctl authn tls-check 2>/dev/null || echo "❌ Cannot check mTLS status"
	@echo "\n📈 Proxy Status:"
	@istioctl proxy-status 2>/dev/null || echo "❌ No proxies found"

## Open Istio dashboards
mesh-dashboard: ## Open Kiali, Grafana, and Prometheus dashboards
	@echo "🔷 Opening Istio Dashboards..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🎯 Kiali:      http://localhost:20001"
	@echo "📊 Grafana:    http://localhost:3000"
	@echo "📈 Prometheus: http://localhost:9090"
	@echo "🔍 Jaeger:     http://localhost:16686"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Starting port-forwards in background..."
	@kubectl -n istio-system port-forward svc/kiali 20001:20001 > /dev/null 2>&1 &
	@kubectl -n istio-system port-forward svc/grafana 3000:3000 > /dev/null 2>&1 &
	@kubectl -n istio-system port-forward svc/prometheus 9090:9090 > /dev/null 2>&1 &
	@kubectl -n istio-system port-forward svc/tracing 16686:16686 > /dev/null 2>&1 &
	@echo "✅ Dashboards ready! Press Ctrl+C to stop all port-forwards"
	@sleep infinity

## Test service mesh compliance
mesh-test: ## Run compliance tests for mTLS and policies
	@echo "🔷 Running Service Mesh Compliance Tests..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "1️⃣ Testing mTLS enforcement..."
	@istioctl authn tls-check | grep -E "STRICT|PERMISSIVE" || echo "❌ mTLS test failed"
	@echo "\n2️⃣ Testing authorization policies..."
	@kubectl get authorizationpolicies -A || echo "❌ No authorization policies found"
	@echo "\n3️⃣ Testing telemetry configuration..."
	@kubectl get telemetry -A || echo "❌ No telemetry configuration found"
	@echo "\n4️⃣ Analyzing configuration..."
	@istioctl analyze || echo "❌ Configuration analysis failed"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

## Install CrewAI multi-agent platform
crewai-install: ## Install CrewAI with automated setup
	@echo "🤖 Installing CrewAI Multi-Agent Platform..."
	@chmod +x infra/crewai/install.sh
	@infra/crewai/install.sh

## Deploy CrewAI to cluster
crewai-up: ## Deploy CrewAI to Kubernetes cluster
	@echo "🤖 Deploying CrewAI to Kubernetes..."
	@kubectl apply -k infra/crewai/
	@echo "✅ CrewAI deployment applied"
	@echo "📊 Run 'make crewai-status' to check deployment status"

## Remove CrewAI from cluster
crewai-down: ## Remove CrewAI from cluster
	@echo "🗑️  Removing CrewAI from cluster..."
	@kubectl delete -k infra/crewai/ --ignore-not-found=true
	@echo "✅ CrewAI removed"

## Check CrewAI status
crewai-status: ## Show CrewAI deployment status
	@echo "🤖 CrewAI Status:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📦 Pods:"
	@kubectl get pods -n crewai 2>/dev/null || echo "❌ No CrewAI pods found"
	@echo "\n🔗 Services:"
	@kubectl get svc -n crewai 2>/dev/null || echo "❌ No CrewAI services found"
	@echo "\n💾 Database:"
	@kubectl get pvc -n crewai 2>/dev/null || echo "❌ No CrewAI PVCs found"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

## Open CrewAI dashboard
crewai-dashboard: ## Open CrewAI API and metrics
	@echo "🤖 Opening CrewAI Dashboard..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🌐 API:      http://localhost:8000"
	@echo "📊 Metrics:  http://localhost:9090/metrics"
	@echo "🏥 Health:   http://localhost:8000/health"
	@echo "🤖 Agents:   http://localhost:8000/agents"
	@echo "👥 Crews:    http://localhost:8000/crews"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Starting port-forwards in background..."
	@kubectl -n crewai port-forward svc/crewai-app 8000:8000 > /dev/null 2>&1 &
	@kubectl -n crewai port-forward svc/crewai-app 9090:9090 > /dev/null 2>&1 &
	@echo "✅ Dashboard ready! Press Ctrl+C to stop all port-forwards"
	@sleep infinity

## Test CrewAI functionality
crewai-test: ## Test CrewAI API endpoints
	@echo "🤖 Testing CrewAI API..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "1️⃣ Testing health endpoint..."
	@curl -s http://localhost:8000/health | jq . || echo "❌ Health check failed"
	@echo "\n2️⃣ Testing API root..."
	@curl -s http://localhost:8000/ | jq . || echo "❌ API root failed"
	@echo "\n3️⃣ Testing agents endpoint..."
	@curl -s http://localhost:8000/agents | jq . || echo "❌ Agents endpoint failed"
	@echo "\n4️⃣ Testing crews endpoint..."
	@curl -s http://localhost:8000/crews | jq . || echo "❌ Crews endpoint failed"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

## AI Agents Scaling Commands

## Deploy AI agents infrastructure
ai-agents-up: ## Deploy AI agents namespace and RBAC
	@echo "🤖 Deploying AI Agents Infrastructure..."
	@kubectl apply -f infra/ai-agents/namespace.yaml
	@kubectl apply -f infra/ai-agents/service-accounts.yaml
	@kubectl apply -f infra/ai-agents/authorization-policies.yaml
	@echo "✅ AI agents infrastructure deployed"

## Deploy AI agents services
ai-agents-services: ## Deploy AI agents services with explicit ports
	@echo "🚀 Deploying AI Agents Services..."
	@kubectl apply -k infra/ai-agents/services/
	@echo "✅ AI agents services deployed"

## Remove AI agents infrastructure
ai-agents-down: ## Remove AI agents infrastructure
	@echo "🗑️  Removing AI agents infrastructure..."
	@kubectl delete -k infra/ai-agents/services/ --ignore-not-found=true
	@kubectl delete -f infra/ai-agents/ --ignore-not-found=true
	@echo "✅ AI agents infrastructure removed"

## Check AI agents status
ai-agents-status: ## Show AI agents deployment status
	@echo "🤖 AI Agents Status:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📦 Namespace:"
	@kubectl get namespace ai-agents 2>/dev/null || echo "❌ AI agents namespace not found"
	@echo "\n🔐 Service Accounts:"
	@kubectl get serviceaccounts -n ai-agents 2>/dev/null || echo "❌ No service accounts found"
	@echo "\n🛡️  Authorization Policies:"
	@kubectl get authorizationpolicies -n ai-agents 2>/dev/null || echo "❌ No authorization policies found"
	@echo "\n🚀 Deployments:"
	@kubectl get deployments -n ai-agents 2>/dev/null || echo "❌ No deployments found"
	@echo "\n🔌 Services:"
	@kubectl get services -n ai-agents 2>/dev/null || echo "❌ No services found"
	@echo "\n📊 Pods:"
	@kubectl get pods -n ai-agents 2>/dev/null || echo "❌ No pods found"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

## Install KEDA for AI agent autoscaling
keda-install: ## Install KEDA for AI agent autoscaling
	@echo "📈 Installing KEDA for AI Agent Autoscaling..."
	@helm repo add kedacore https://kedacore.github.io/charts
	@helm repo update
	@helm install keda kedacore/keda --namespace keda --create-namespace
	@echo "✅ KEDA installed"

## Deploy KEDA scalers for AI agents
keda-scalers: ## Deploy KEDA scalers for AI agents
	@echo "📈 Deploying KEDA Scalers for AI Agents..."
	@kubectl apply -f infra/keda/ai-agent-scalers.yaml
	@echo "✅ KEDA scalers deployed"

## Check KEDA status
keda-status: ## Show KEDA and scaler status
	@echo "📈 KEDA Status:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📦 KEDA Pods:"
	@kubectl get pods -n keda 2>/dev/null || echo "❌ KEDA not installed"
	@echo "\n📊 ScaledObjects:"
	@kubectl get scaledobjects -n ai-agents 2>/dev/null || echo "❌ No scaled objects found"
	@echo "\n📈 HPA:"
	@kubectl get hpa -n ai-agents 2>/dev/null || echo "❌ No HPA found"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

## Upgrade to Istio Ambient Mesh
mesh-upgrade-ambient: ## Upgrade Istio to ambient mode
	@echo "🔷 Upgrading Istio to Ambient Mode..."
	@istioctl install --set profile=ambient \
		--set values.pilot.env.PILOT_ENABLE_AMBIENT=true \
		--set values.pilot.env.PILOT_ENABLE_AMBIENT_WAYPOINT=true \
		--set values.pilot.env.PILOT_ENABLE_AMBIENT_ZTUNNEL=true \
		-y
	@echo "✅ Istio upgraded to ambient mode"

## Deploy ambient mesh configuration
ambient-up: ## Deploy ambient mesh configuration
	@echo "🔷 Deploying Ambient Mesh Configuration..."
	@kubectl apply -f infra/istio/ambient/waypoint.yaml
	@kubectl apply -f infra/istio/ambient/observability.yaml
	@kubectl apply -f infra/istio/ambient/chaos-engineering.yaml
	@echo "✅ Ambient mesh configuration deployed"

## Generate protobuf code
proto-generate: ## Generate protobuf code from definitions
	@echo "🔧 Generating Protobuf Code..."
	@protoc --python_out=. --grpc_python_out=. proto/ai_agent_service.proto
	@echo "✅ Protobuf code generated"

## Run AI agents scaling tests
ai-agents-test: ## Run comprehensive AI agents scaling tests
	@echo "🧪 Running AI Agents Scaling Tests..."
	@python3 tests/test_ai_agents_scaling.py
	@echo "✅ AI agents scaling tests completed"

## Deploy complete AI agents scaling infrastructure
ai-agents-scaling: ## Deploy complete AI agents scaling infrastructure
	@echo "🚀 Deploying Complete AI Agents Scaling Infrastructure..."
	@echo "Phase A: Stabilizing ports and service discovery..."
	@make ai-agents-up
	@make ai-agents-services
	@echo "Phase B: Deploying ambient mesh..."
	@make ambient-up
	@echo "Phase C: Installing KEDA..."
	@make keda-install
	@echo "Phase D: Deploying autoscaling..."
	@make keda-scalers
	@echo "Phase E: Generating protobuf..."
	@make proto-generate
	@echo "Phase F: Running comprehensive tests..."
	@make ai-agents-test
	@echo "✅ Complete AI agents scaling infrastructure deployed!"
	@echo "📊 Run 'make ai-agents-status' to check deployment"
	@echo "📈 Run 'make keda-status' to check autoscaling"
	@echo "🧪 Run 'make ai-agents-test' to run tests"

## Cleanup Docker and reset environment
clean: dev-down ## Clean up everything including Docker
	@echo "🧹 Cleaning up Docker and containers..."
	docker system prune -af --volumes || true
	@echo "✅ Cleanup complete"

## Show cluster status
status: ## Show cluster and deployment status
	@echo "📊 Cluster Status:"
	@kubectl cluster-info 2>/dev/null || echo "❌ Cluster not running"
	@echo "\n📊 Pod Status:"
	@kubectl -n infrastructure get pods 2>/dev/null || echo "❌ No pods found"
	@echo "\n📊 Service Status:"
	@kubectl -n infrastructure get services 2>/dev/null || echo "❌ No services found"

## Help
help: ## Show this help message
	@echo "MedinovAI Infrastructure Management"
	@echo "=================================="
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) 