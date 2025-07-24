# CrewAI Installation Guide for MedinovAI

## Overview

CrewAI is a multi-agent orchestration platform that enables teams of AI agents to work together on complex tasks. This guide covers the installation and setup of CrewAI in your local Docker-Kubernetes environment.

## Prerequisites

- Kubernetes cluster (KinD, k3d, or Docker Desktop Kubernetes)
- kubectl configured and accessible
- Docker Desktop running
- At least 4GB RAM available for the cluster

## Quick Installation

### 1. Deploy CrewAI

```bash
# Deploy CrewAI to Kubernetes
make crewai-up

# Check deployment status
make crewai-status
```

### 2. Access the API

```bash
# Open CrewAI dashboard with port forwarding
make crewai-dashboard

# Or manually set up port forwarding
kubectl port-forward -n crewai svc/crewai-app 8000:8000
```

### 3. Test the Installation

```bash
# Test API endpoints
make crewai-test

# Or test manually
curl http://localhost:8000/health
curl http://localhost:8000/
curl http://localhost:8000/agents
curl http://localhost:8000/crews
```

## Architecture

### Components

1. **CrewAI Application** (`crewai-app`)
   - FastAPI-based REST API
   - Multi-agent orchestration engine
   - PostgreSQL database integration
   - Prometheus metrics endpoint

2. **PostgreSQL Database** (`crewai-postgresql`)
   - Persistent storage for agents, crews, and processes
   - Automatic schema initialization
   - 10GB persistent volume

3. **Configuration Management**
   - ConfigMap for application settings
   - Secret for API keys and sensitive data
   - Environment-specific configurations

### Network Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   External      │    │   Kubernetes    │    │   PostgreSQL    │
│   Client        │───▶│   Service       │───▶│   Database      │
│                 │    │   (8000)        │    │   (5432)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   CrewAI App    │
                       │   (FastAPI)     │
                       └─────────────────┘
```

## Configuration

### Environment Variables

The following environment variables are automatically configured:

- `DATABASE_URL`: PostgreSQL connection string
- `DATABASE_PASSWORD`: Database password (from secret)
- `OPENAI_API_KEY`: OpenAI API key (from secret)
- `ANTHROPIC_API_KEY`: Anthropic API key (from secret)
- `GOOGLE_API_KEY`: Google API key (from secret)
- `SERPER_API_KEY`: Serper API key (from secret)
- `TAVILY_API_KEY`: Tavily API key (from secret)
- `LANGCHAIN_API_KEY`: LangChain API key (from secret)

### Updating API Keys

To update API keys, edit the secret:

```bash
# Edit the secret file
kubectl edit secret crewai-secrets -n crewai

# Or update the secret file and reapply
kubectl apply -f infra/crewai/secret.yaml
```

## API Endpoints

### Health and Status

- `GET /health` - Health check endpoint
- `GET /ready` - Readiness check endpoint
- `GET /` - API root with version information

### Agent Management

- `GET /agents` - List all agents
- `POST /agents` - Create a new agent
- `GET /agents/{id}` - Get agent details
- `PUT /agents/{id}` - Update agent
- `DELETE /agents/{id}` - Delete agent

### Crew Management

- `GET /crews` - List all crews
- `POST /crews` - Create a new crew
- `GET /crews/{id}` - Get crew details
- `PUT /crews/{id}` - Update crew
- `DELETE /crews/{id}` - Delete crew

### Process Execution

- `POST /process` - Execute a crew process
- `GET /processes/{id}` - Get process status
- `GET /processes` - List all processes

### Monitoring

- `GET /metrics` - Prometheus metrics endpoint

## Usage Examples

### Creating an Agent

```bash
curl -X POST http://localhost:8000/agents \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Research Agent",
    "role": "Research Specialist",
    "goal": "Conduct comprehensive research on given topics",
    "backstory": "Expert researcher with 10+ years experience",
    "verbose": true,
    "allow_delegation": false,
    "tools": ["web_search", "file_operations"]
  }'
```

### Creating a Crew

```bash
curl -X POST http://localhost:8000/crews \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Research Team",
    "description": "Team for conducting research projects",
    "agents": [
      {
        "name": "Research Agent",
        "role": "Research Specialist",
        "goal": "Conduct research",
        "backstory": "Expert researcher"
      }
    ],
    "tasks": [
      {
        "description": "Research the latest AI developments",
        "expected_output": "Comprehensive report on AI trends"
      }
    ]
  }'
```

### Executing a Process

```bash
curl -X POST http://localhost:8000/process \
  -H "Content-Type: application/json" \
  -d '{
    "crew_id": 1,
    "process_type": "sequential",
    "verbose": true,
    "memory": true,
    "cache": true
  }'
```

## Monitoring and Observability

### Metrics

CrewAI exposes Prometheus metrics at `/metrics`:

- `crewai_requests_total` - Total API requests
- `crewai_request_duration_seconds` - Request latency
- `crewai_active_agents` - Number of active agents
- `crewai_active_crews` - Number of active crews

### Logs

View application logs:

```bash
# View CrewAI app logs
kubectl logs -n crewai -l app=crewai-app

# View PostgreSQL logs
kubectl logs -n crewai -l app=crewai-postgresql

# Follow logs in real-time
kubectl logs -n crewai -l app=crewai-app -f
```

### Health Checks

The application includes health checks:

```bash
# Health check
curl http://localhost:8000/health

# Readiness check
curl http://localhost:8000/ready
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   # Check pod events
   kubectl describe pod -n crewai -l app=crewai-app
   
   # Check logs
   kubectl logs -n crewai -l app=crewai-app
   ```

2. **Database connection issues**
   ```bash
   # Check PostgreSQL status
   kubectl get pods -n crewai -l app=crewai-postgresql
   
   # Check database logs
   kubectl logs -n crewai -l app=crewai-postgresql
   ```

3. **API not accessible**
   ```bash
   # Check service status
   kubectl get svc -n crewai
   
   # Check port forwarding
   kubectl port-forward -n crewai svc/crewai-app 8000:8000
   ```

### Resource Issues

If you encounter resource constraints:

```bash
# Check resource usage
kubectl top pods -n crewai

# Scale down if needed
kubectl scale deployment crewai-app -n crewai --replicas=1
```

## Management Commands

### Makefile Targets

```bash
# Install CrewAI
make crewai-install

# Deploy to cluster
make crewai-up

# Check status
make crewai-status

# Open dashboard
make crewai-dashboard

# Test functionality
make crewai-test

# Remove from cluster
make crewai-down
```

### Manual Commands

```bash
# Apply configuration
kubectl apply -k infra/crewai/

# Delete deployment
kubectl delete -k infra/crewai/

# View resources
kubectl get all -n crewai

# View secrets
kubectl get secrets -n crewai

# View configmaps
kubectl get configmaps -n crewai
```

## Security Considerations

1. **API Keys**: Store API keys in Kubernetes secrets
2. **Network Security**: Use Istio service mesh for mTLS
3. **Access Control**: Implement RBAC for Kubernetes resources
4. **Data Encryption**: Enable encryption at rest for PostgreSQL

## Scaling

### Horizontal Scaling

```bash
# Scale CrewAI app
kubectl scale deployment crewai-app -n crewai --replicas=3

# Scale PostgreSQL (requires StatefulSet)
kubectl scale statefulset crewai-postgresql -n crewai --replicas=2
```

### Resource Limits

Adjust resource limits in `infra/crewai/crewai-app.yaml`:

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

## Backup and Recovery

### Database Backup

```bash
# Create backup
kubectl exec -n crewai deployment/crewai-postgresql -- \
  pg_dump -U crewai crewai > backup.sql

# Restore backup
kubectl exec -n crewai deployment/crewai-postgresql -- \
  psql -U crewai crewai < backup.sql
```

### Configuration Backup

```bash
# Backup configurations
kubectl get configmap crewai-config -n crewai -o yaml > config-backup.yaml
kubectl get secret crewai-secrets -n crewai -o yaml > secrets-backup.yaml
```

## Next Steps

1. **Configure API Keys**: Update the secret with your actual API keys
2. **Create Agents**: Define your first AI agents
3. **Create Crews**: Set up agent teams
4. **Execute Processes**: Run your first multi-agent workflows
5. **Monitor Performance**: Set up Grafana dashboards
6. **Integrate with MedinovAI**: Connect with existing services

## Support

For issues and questions:

1. Check the logs: `kubectl logs -n crewai -l app=crewai-app`
2. Review this documentation
3. Check CrewAI official documentation
4. Review Kubernetes events: `kubectl get events -n crewai`

---

**CrewAI is now successfully installed and ready for multi-agent orchestration!** 🤖 