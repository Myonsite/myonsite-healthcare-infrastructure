#!/bin/bash

# CrewAI Installation Script for Kubernetes
# MedinovAI Multi-Agent Orchestration Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Preflight checks
preflight_check() {
    log "Running preflight checks..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check if namespace exists
    if kubectl get namespace crewai &> /dev/null; then
        warning "Namespace 'crewai' already exists"
    fi
    
    success "Preflight checks passed"
}

# Update secrets with real values
update_secrets() {
    log "Updating CrewAI secrets..."
    
    # Check if secrets file exists
    if [ ! -f "infra/crewai/secret.yaml" ]; then
        error "Secret file not found"
        exit 1
    fi
    
    # Prompt for API keys
    echo
    log "Please provide your API keys (press Enter to skip):"
    
    read -p "OpenAI API Key: " openai_key
    read -p "Anthropic API Key: " anthropic_key
    read -p "Google API Key: " google_key
    read -p "Serper API Key: " serper_key
    read -p "Tavily API Key: " tavily_key
    read -p "LangChain API Key: " langchain_key
    
    # Update secret file with provided keys
    if [ ! -z "$openai_key" ]; then
        openai_encoded=$(echo -n "$openai_key" | base64)
        sed -i.bak "s/openai_api_key:.*/openai_api_key: $openai_encoded/" infra/crewai/secret.yaml
    fi
    
    if [ ! -z "$anthropic_key" ]; then
        anthropic_encoded=$(echo -n "$anthropic_key" | base64)
        sed -i.bak "s/anthropic_api_key:.*/anthropic_api_key: $anthropic_encoded/" infra/crewai/secret.yaml
    fi
    
    if [ ! -z "$google_key" ]; then
        google_encoded=$(echo -n "$google_key" | base64)
        sed -i.bak "s/google_api_key:.*/google_api_key: $google_encoded/" infra/crewai/secret.yaml
    fi
    
    if [ ! -z "$serper_key" ]; then
        serper_encoded=$(echo -n "$serper_key" | base64)
        sed -i.bak "s/serper_api_key:.*/serper_api_key: $serper_encoded/" infra/crewai/secret.yaml
    fi
    
    if [ ! -z "$tavily_key" ]; then
        tavily_encoded=$(echo -n "$tavily_key" | base64)
        sed -i.bak "s/tavily_api_key:.*/tavily_api_key: $tavily_encoded/" infra/crewai/secret.yaml
    fi
    
    if [ ! -z "$langchain_key" ]; then
        langchain_encoded=$(echo -n "$langchain_key" | base64)
        sed -i.bak "s/langchain_api_key:.*/langchain_api_key: $langchain_encoded/" infra/crewai/secret.yaml
    fi
    
    # Clean up backup files
    rm -f infra/crewai/secret.yaml.bak
    
    success "Secrets updated"
}

# Deploy CrewAI
deploy_crewai() {
    log "Deploying CrewAI to Kubernetes..."
    
    # Apply Kustomization
    kubectl apply -k infra/crewai/
    
    # Wait for PostgreSQL to be ready
    log "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=crewai-postgresql -n crewai --timeout=300s
    
    # Wait for CrewAI app to be ready
    log "Waiting for CrewAI application to be ready..."
    kubectl wait --for=condition=ready pod -l app=crewai-app -n crewai --timeout=300s
    
    success "CrewAI deployed successfully"
}

# Setup port forwarding
setup_port_forward() {
    log "Setting up port forwarding..."
    
    # Kill existing port forwards
    pkill -f "kubectl.*port-forward.*crewai" || true
    
    # Start port forwarding in background
    kubectl port-forward -n crewai service/crewai-app 8000:8000 &
    kubectl port-forward -n crewai service/crewai-app 9090:9090 &
    
    success "Port forwarding started"
    echo
    log "CrewAI API available at: http://localhost:8000"
    log "CrewAI Metrics available at: http://localhost:9090/metrics"
    log "CrewAI Health check: http://localhost:8000/health"
}

# Test the installation
test_installation() {
    log "Testing CrewAI installation..."
    
    # Wait a moment for services to be fully ready
    sleep 10
    
    # Test health endpoint
    if curl -s http://localhost:8000/health | grep -q "healthy"; then
        success "Health check passed"
    else
        error "Health check failed"
        return 1
    fi
    
    # Test API endpoints
    if curl -s http://localhost:8000/ | grep -q "CrewAI API"; then
        success "API root endpoint working"
    else
        error "API root endpoint failed"
        return 1
    fi
    
    # Test agents endpoint
    if curl -s http://localhost:8000/agents | grep -q "\[\]"; then
        success "Agents endpoint working"
    else
        error "Agents endpoint failed"
        return 1
    fi
    
    success "All tests passed"
}

# Print usage information
print_usage() {
    echo
    log "CrewAI Installation Complete!"
    echo
    echo "📊 Available Endpoints:"
    echo "   API: http://localhost:8000"
    echo "   Health: http://localhost:8000/health"
    echo "   Metrics: http://localhost:9090/metrics"
    echo "   Agents: http://localhost:8000/agents"
    echo "   Crews: http://localhost:8000/crews"
    echo
    echo "🔧 Management Commands:"
    echo "   View logs: kubectl logs -n crewai -l app=crewai-app"
    echo "   View pods: kubectl get pods -n crewai"
    echo "   View services: kubectl get svc -n crewai"
    echo "   Delete deployment: kubectl delete -k infra/crewai/"
    echo
    echo "📚 Next Steps:"
    echo "   1. Create your first agent: POST http://localhost:8000/agents"
    echo "   2. Create a crew: POST http://localhost:8000/crews"
    echo "   3. Execute a process: POST http://localhost:8000/process"
    echo
    echo "🚀 CrewAI is ready for multi-agent orchestration!"
}

# Main installation function
main() {
    echo
    log "Starting CrewAI installation for MedinovAI..."
    echo
    
    preflight_check
    update_secrets
    deploy_crewai
    setup_port_forward
    test_installation
    print_usage
    
    success "CrewAI installation completed successfully!"
}

# Run main function
main "$@" 