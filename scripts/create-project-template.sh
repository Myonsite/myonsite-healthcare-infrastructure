#!/bin/bash
# create-project-template.sh
# Automated project template creation for healthcare projects with AI tools integration

set -e

PROJECT_NAME=$1
PROJECT_TYPE=$2
TEAM_SIZE=${3:-3}

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_TYPE" ]; then
    echo "Usage: ./create-project-template.sh <project_name> <project_type> [team_size]"
    echo "Example: ./create-project-template.sh clinical-trials clinical_trials 3"
    echo ""
    echo "Available project types:"
    echo "  - clinical_trials"
    echo "  - ehr_system"
    echo "  - telemedicine"
    echo "  - pharmacy_management"
    echo "  - laboratory_lims"
    echo "  - hospital_management"
    echo "  - medical_imaging"
    echo "  - precision_medicine"
    exit 1
fi

echo "🏥 Creating AI-managed healthcare project: $PROJECT_NAME"
echo "📋 Project type: $PROJECT_TYPE"
echo "👥 Team size: $TEAM_SIZE"
echo ""

# Create project directory structure
echo "📁 Creating project structure..."
mkdir -p $PROJECT_NAME/{requirements,ai-agents,team,frontend,backend,database,deployment/{kubernetes,monitoring,compliance},docs,scripts,tests,config}

# Create README
echo "📝 Creating README..."
cat > $PROJECT_NAME/README.md << EOF
# $PROJECT_NAME

## 🏥 Overview
AI-managed healthcare application for $PROJECT_TYPE using modern AI tools (Cursor, Claude Code, GitHub Copilot, CrewAI).

## 🚀 Quick Start
\`\`\`bash
# Deploy AI agents
kubectl apply -f ai-agents/

# Monitor progress
make mesh-dashboard

# Check status
kubectl get pods -n ai-agents
\`\`\`

## 🛠️ AI Tools Integration
- **Cursor IDE**: Real-time coding assistance and code generation
- **Claude Code**: Complex algorithm and business logic generation
- **GitHub Copilot**: Pair programming and inline assistance
- **CrewAI**: Multi-agent orchestration and task automation

## 👥 Team
- Frontend Developer: [Name] - React, TypeScript, UI/UX
- Backend Developer: [Name] - Python, FastAPI, PostgreSQL
- Compliance Specialist: [Name] - HIPAA, FDA, Audit Trails

## 🔒 Compliance Requirements
- HIPAA (Health Insurance Portability and Accountability Act)
- FDA 21 CFR Part 11 (Electronic Records and Signatures)
- GDPR (General Data Protection Regulation)
- ISO 13485 (Medical Device Quality Management)

## 📊 Success Metrics
- Time to Market: < 8 weeks
- Code Quality Score: > 90%
- Test Coverage: > 95%
- Compliance Score: 100%
- User Satisfaction: > 90%

## 🎯 Development Process
1. **AI-Assisted Requirements Analysis** (Week 1)
2. **AI-Generated Specification Creation** (Week 1)
3. **AI-Powered Implementation** (Weeks 2-4)
4. **AI-Automated Testing & QA** (Week 5)
5. **AI-Enhanced Review & Approval** (Week 6)
6. **AI-Managed Deployment** (Week 7)
7. **AI-Driven Maintenance** (Week 8)

## 📁 Project Structure
\`\`\`
$PROJECT_NAME/
├── requirements/          # Business requirements and user stories
├── ai-agents/            # AI agent configurations
├── team/                 # Team member configurations
├── frontend/             # React/TypeScript frontend
├── backend/              # Python/FastAPI backend
├── database/             # Database schemas and migrations
├── deployment/           # Kubernetes and monitoring configs
├── docs/                 # Documentation
├── scripts/              # Automation scripts
├── tests/                # Test suites
└── config/               # Configuration files
\`\`\`

## 🔧 AI Tools Configuration
- **.cursorrules**: Cursor IDE configuration for healthcare development
- **claude-config.yaml**: Claude Code settings and prompts
- **copilot-config.json**: GitHub Copilot configuration
- **crewai-config.yaml**: CrewAI agent orchestration settings

## 📈 Monitoring & Dashboards
- **Application Health**: Real-time application monitoring
- **AI Agent Performance**: AI agent metrics and performance
- **Compliance Status**: Regulatory compliance tracking
- **Team Performance**: Developer productivity metrics

## 🚨 Troubleshooting
- Check AI agent status: \`kubectl get pods -n ai-agents\`
- View AI agent logs: \`kubectl logs -n ai-agents deployment/ai-agent-orchestrator\`
- Monitor compliance: \`./scripts/validate-compliance.sh $PROJECT_NAME\`
- Performance monitoring: \`./scripts/monitor-performance.sh $PROJECT_NAME\`
EOF

# Create requirements files
echo "📋 Creating requirements..."
cat > $PROJECT_NAME/requirements/user-stories.md << EOF
# User Stories - $PROJECT_NAME

## As a [User Role]
- I want to [Action/Feature]
- So that [Business Value/Benefit]

### Acceptance Criteria
- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]
- [ ] [Specific requirement 3]

### Compliance Requirements
- [ ] HIPAA compliance
- [ ] FDA 21 CFR Part 11 compliance
- [ ] Audit trail maintenance
- [ ] Data encryption at rest and in transit

### AI Tools Integration
- **Cursor AI**: Real-time code suggestions and improvements
- **Claude Code**: Complex business logic generation
- **GitHub Copilot**: Inline documentation and error handling
- **CrewAI**: Automated testing and compliance validation
EOF

cat > $PROJECT_NAME/requirements/compliance-checklist.md << EOF
# Compliance Checklist - $PROJECT_NAME

## HIPAA Compliance
- [ ] Data encryption at rest
- [ ] Data encryption in transit
- [ ] Access controls and authentication
- [ ] Audit trails for all data access
- [ ] Data backup and recovery procedures
- [ ] Privacy controls and consent management

## FDA 21 CFR Part 11 Compliance
- [ ] Electronic records integrity
- [ ] Electronic signatures
- [ ] Audit trails for all changes
- [ ] System validation and testing
- [ ] User access controls
- [ ] Record retention policies

## GDPR Compliance
- [ ] Data minimization
- [ ] User consent management
- [ ] Right to erasure
- [ ] Data portability
- [ ] Privacy by design
- [ ] Data protection impact assessment

## Security Requirements
- [ ] Multi-factor authentication
- [ ] Role-based access control (RBAC)
- [ ] Vulnerability scanning and patching
- [ ] Security incident response procedures
- [ ] Regular security audits
- [ ] Penetration testing
EOF

cat > $PROJECT_NAME/requirements/technical-requirements.md << EOF
# Technical Requirements - $PROJECT_NAME

## Architecture Requirements
- **Frontend**: React 18+ with TypeScript
- **Backend**: Python 3.11+ with FastAPI
- **Database**: PostgreSQL 15+ with encryption
- **Security**: mTLS, JWT, RBAC
- **Monitoring**: Prometheus, Grafana, Jaeger
- **Compliance**: Automated compliance checking

## Performance Requirements
- **Response Time**: < 100ms P95
- **Throughput**: 1000+ RPS
- **Availability**: 99.9% uptime
- **Scalability**: Support 1000+ concurrent users

## AI Tools Integration
- **Cursor IDE**: Real-time coding assistance
- **Claude Code**: Complex algorithm generation
- **GitHub Copilot**: Pair programming support
- **CrewAI**: Multi-agent orchestration

## Testing Requirements
- **Unit Test Coverage**: > 95%
- **Integration Test Coverage**: > 90%
- **E2E Test Coverage**: > 85%
- **Compliance Test Coverage**: 100%

## Deployment Requirements
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes with Istio service mesh
- **CI/CD**: Automated deployment pipelines
- **Monitoring**: Real-time application monitoring
EOF

# Create AI agent configurations
echo "🤖 Creating AI agent configurations..."
cat > $PROJECT_NAME/ai-agents/project-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $PROJECT_NAME-config
  namespace: ai-agents
data:
  project_name: "$PROJECT_NAME"
  project_type: "$PROJECT_TYPE"
  team_size: "$TEAM_SIZE"
  estimated_duration: "8 weeks"
  
  compliance_requirements: |
    - HIPAA
    - FDA_21_CFR_PART_11
    - GDPR
    - ISO_13485
  
  ai_tools_integration: |
    - cursor_ide: "Real-time coding assistance"
    - claude_code: "Complex algorithm generation"
    - github_copilot: "Pair programming support"
    - crewai: "Multi-agent orchestration"
  
  ai_agents_config: |
    orchestrator:
      replicas: 1
      focus: ["project_coordination", "task_assignment"]
      ai_tools: ["cursor_ai", "claude_code"]
    
    coding_agents:
      frontend:
        replicas: 2
        focus: ["React", "TypeScript", "UI/UX"]
        ai_tools: ["cursor_ai", "github_copilot"]
        team_member: "Frontend Developer"
      
      backend:
        replicas: 2
        focus: ["Python", "FastAPI", "PostgreSQL"]
        ai_tools: ["cursor_ai", "claude_code"]
        team_member: "Backend Developer"
      
      database:
        replicas: 1
        focus: ["Database Design", "Migrations", "Optimization"]
        ai_tools: ["claude_code", "cursor_ai"]
        team_member: "Backend Developer"
    
    testing_agents:
      unit:
        replicas: 2
        focus: ["Unit Tests", "Code Coverage"]
        ai_tools: ["claude_code", "github_copilot"]
      
      integration:
        replicas: 2
        focus: ["API Tests", "Integration Tests", "E2E Tests"]
        ai_tools: ["claude_code", "cursor_ai"]
    
    compliance_agents:
      hipaa:
        replicas: 1
        focus: ["HIPAA", "Data Protection", "Privacy"]
        ai_tools: ["claude_code", "crewai"]
        team_member: "Compliance Specialist"
      
      fda:
        replicas: 1
        focus: ["FDA 21 CFR Part 11", "Audit Trails", "Validation"]
        ai_tools: ["claude_code", "crewai"]
        team_member: "Compliance Specialist"
    
    security_agents:
      scanning:
        replicas: 1
        focus: ["SAST", "DAST", "Vulnerability Scanning"]
        ai_tools: ["cursor_ai", "claude_code"]
      
      access_control:
        replicas: 1
        focus: ["Authentication", "Authorization", "RBAC"]
        ai_tools: ["claude_code", "cursor_ai"]
EOF

# Create team configurations
echo "👥 Creating team configurations..."
cat > $PROJECT_NAME/team/frontend-developer.yaml << EOF
# Frontend Developer Configuration
developer:
  name: "[Frontend Developer Name]"
  role: "Frontend Developer"
  experience: "Junior"
  focus_areas:
    - "React Components"
    - "TypeScript Development"
    - "User Interface Design"
    - "User Experience"
    - "Accessibility (WCAG 2.1 AA)"
  
  ai_tools_support:
    cursor_ai:
      - "Real-time code completion"
      - "Component generation"
      - "Refactoring assistance"
      - "Performance optimization"
    
    claude_code:
      - "Complex UI logic generation"
      - "State management patterns"
      - "Testing strategy"
      - "Documentation generation"
    
    github_copilot:
      - "Inline code suggestions"
      - "Component documentation"
      - "Error handling patterns"
      - "Best practice recommendations"
  
  daily_tasks:
    - "Review AI-generated frontend code"
    - "Customize business-specific UI components"
    - "Test user workflows and accessibility"
    - "Validate responsive design"
    - "Optimize performance and user experience"
  
  learning_objectives:
    - "Master React 18+ features"
    - "Understand TypeScript best practices"
    - "Learn healthcare UI/UX patterns"
    - "Develop accessibility expertise"
    - "Understand compliance requirements"
EOF

cat > $PROJECT_NAME/team/backend-developer.yaml << EOF
# Backend Developer Configuration
developer:
  name: "[Backend Developer Name]"
  role: "Backend Developer"
  experience: "Junior"
  focus_areas:
    - "API Development"
    - "Database Design"
    - "Business Logic"
    - "Security Implementation"
    - "Performance Optimization"
  
  ai_tools_support:
    cursor_ai:
      - "Real-time API development"
      - "Database query optimization"
      - "Security implementation"
      - "Error handling patterns"
    
    claude_code:
      - "Complex business logic generation"
      - "Database schema design"
      - "API specification generation"
      - "Testing strategy development"
    
    github_copilot:
      - "Inline code documentation"
      - "Error handling suggestions"
      - "Best practice recommendations"
      - "Security pattern implementation"
  
  daily_tasks:
    - "Review AI-generated API endpoints"
    - "Implement business-specific logic"
    - "Design and optimize database schemas"
    - "Validate data integrity and security"
    - "Monitor API performance"
  
  learning_objectives:
    - "Master FastAPI framework"
    - "Understand PostgreSQL optimization"
    - "Learn healthcare data patterns"
    - "Develop security expertise"
    - "Understand compliance requirements"
EOF

cat > $PROJECT_NAME/team/compliance-specialist.yaml << EOF
# Compliance Specialist Configuration
developer:
  name: "[Compliance Specialist Name]"
  role: "Compliance Specialist"
  experience: "Junior"
  focus_areas:
    - "HIPAA Compliance"
    - "FDA Requirements"
    - "Audit Trails"
    - "Data Protection"
    - "Regulatory Validation"
  
  ai_tools_support:
    cursor_ai:
      - "Compliance code review"
      - "Audit trail validation"
      - "Security pattern verification"
      - "Documentation review"
    
    claude_code:
      - "Compliance requirement analysis"
      - "Audit trail generation"
      - "Regulatory documentation"
      - "Compliance testing strategy"
    
    crewai:
      - "Automated compliance checking"
      - "Regulatory validation"
      - "Audit report generation"
      - "Compliance monitoring"
  
  daily_tasks:
    - "Review compliance reports from AI agents"
    - "Validate regulatory requirements"
    - "Document compliance measures"
    - "Prepare audit documentation"
    - "Monitor compliance status"
  
  learning_objectives:
    - "Master HIPAA requirements"
    - "Understand FDA 21 CFR Part 11"
    - "Learn audit trail implementation"
    - "Develop compliance expertise"
    - "Understand healthcare regulations"
EOF

# Create AI tools configuration files
echo "🛠️ Creating AI tools configurations..."
cat > $PROJECT_NAME/config/.cursorrules << EOF
# Cursor IDE Configuration for Healthcare Development
{
  "project_type": "healthcare",
  "compliance_requirements": ["HIPAA", "FDA_21_CFR_PART_11", "GDPR"],
  "coding_standards": {
    "frontend": {
      "language": "typescript",
      "framework": "react",
      "testing": "jest",
      "linting": "eslint"
    },
    "backend": {
      "language": "python",
      "framework": "fastapi",
      "testing": "pytest",
      "linting": "flake8"
    }
  },
  "ai_assistance": {
    "code_completion": true,
    "refactoring": true,
    "documentation": true,
    "testing": true,
    "security": true,
    "compliance": true
  },
  "healthcare_specific": {
    "data_encryption": true,
    "audit_trails": true,
    "access_controls": true,
    "privacy_protection": true
  }
}
EOF

cat > $PROJECT_NAME/config/claude-config.yaml << EOF
# Claude Code Configuration
claude_code:
  project:
    name: "$PROJECT_NAME"
    type: "$PROJECT_TYPE"
    domain: "healthcare"
  
  compliance_requirements:
    - "HIPAA"
    - "FDA_21_CFR_PART_11"
    - "GDPR"
    - "ISO_13485"
  
  code_generation:
    frontend:
      framework: "React"
      language: "TypeScript"
      styling: "Tailwind CSS"
      testing: "Jest + React Testing Library"
    
    backend:
      framework: "FastAPI"
      language: "Python"
      database: "PostgreSQL"
      testing: "Pytest"
  
  security_requirements:
    - "Data encryption at rest and in transit"
    - "Multi-factor authentication"
    - "Role-based access control"
    - "Audit trails for all actions"
    - "Input validation and sanitization"
  
  testing_strategy:
    unit_tests: "95% coverage"
    integration_tests: "90% coverage"
    e2e_tests: "85% coverage"
    compliance_tests: "100% coverage"
    security_tests: "100% coverage"
EOF

cat > $PROJECT_NAME/config/copilot-config.json << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "type": "$PROJECT_TYPE",
    "domain": "healthcare"
  },
  "assistance": {
    "code_completion": true,
    "documentation": true,
    "testing": true,
    "security": true,
    "compliance": true
  },
  "languages": {
    "typescript": {
      "framework": "react",
      "testing": "jest"
    },
    "python": {
      "framework": "fastapi",
      "testing": "pytest"
    }
  },
  "healthcare_specific": {
    "data_protection": true,
    "audit_trails": true,
    "compliance_checking": true,
    "security_patterns": true
  }
}
EOF

cat > $PROJECT_NAME/config/crewai-config.yaml << EOF
# CrewAI Configuration
crewai:
  project:
    name: "$PROJECT_NAME"
    type: "$PROJECT_TYPE"
    domain: "healthcare"
  
  agents:
    orchestrator:
      name: "Project Orchestrator"
      role: "Coordinate all development activities"
      tools: ["cursor_ai", "claude_code", "github_copilot"]
    
    coding_agent:
      name: "Coding Agent"
      role: "Generate and review code"
      tools: ["cursor_ai", "claude_code"]
      focus: ["frontend", "backend", "database"]
    
    testing_agent:
      name: "Testing Agent"
      role: "Generate and execute tests"
      tools: ["claude_code", "github_copilot"]
      focus: ["unit_tests", "integration_tests", "e2e_tests"]
    
    compliance_agent:
      name: "Compliance Agent"
      role: "Validate regulatory compliance"
      tools: ["claude_code", "cursor_ai"]
      focus: ["hipaa", "fda", "gdpr"]
    
    security_agent:
      name: "Security Agent"
      role: "Validate security requirements"
      tools: ["cursor_ai", "claude_code"]
      focus: ["authentication", "authorization", "encryption"]
  
  workflows:
    development:
      - "requirements_analysis"
      - "code_generation"
      - "testing"
      - "compliance_validation"
      - "security_validation"
      - "deployment"
    
    quality_assurance:
      - "code_review"
      - "test_execution"
      - "compliance_checking"
      - "security_scanning"
      - "performance_testing"
EOF

# Create deployment configurations
echo "🚀 Creating deployment configurations..."
cat > $PROJECT_NAME/deployment/kubernetes/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $PROJECT_NAME-app
  namespace: $PROJECT_NAME
  labels:
    app: $PROJECT_NAME
    project-type: $PROJECT_TYPE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $PROJECT_NAME
  template:
    metadata:
      labels:
        app: $PROJECT_NAME
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: app
        image: $PROJECT_NAME:latest
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: grpc
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: $PROJECT_NAME-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: $PROJECT_NAME-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: $PROJECT_NAME-service
  namespace: $PROJECT_NAME
spec:
  selector:
    app: $PROJECT_NAME
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: grpc
    port: 9090
    targetPort: 9090
  type: ClusterIP
EOF

cat > $PROJECT_NAME/deployment/monitoring/dashboard.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $PROJECT_NAME-dashboard
  namespace: monitoring
data:
  dashboard.json: |
    {
      "title": "$PROJECT_NAME Dashboard",
      "refresh": "30s",
      "panels": [
        {
          "title": "Application Health",
          "type": "stat",
          "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
          "targets": [
            {
              "expr": "up{app=\"$PROJECT_NAME\"}",
              "legendFormat": "{{instance}}"
            }
          ]
        },
        {
          "title": "Response Time (P95)",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 6, "y": 0},
          "targets": [
            {
              "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app=\"$PROJECT_NAME\"}[5m]))",
              "legendFormat": "P95 Response Time"
            }
          ]
        },
        {
          "title": "Error Rate",
          "type": "graph",
          "gridPos": {"h": 8, "w": 6, "x": 0, "y": 8},
          "targets": [
            {
              "expr": "rate(http_requests_total{app=\"$PROJECT_NAME\", status=~\"5..\"}[5m])",
              "legendFormat": "5xx Errors"
            }
          ]
        },
        {
          "title": "AI Agent Performance",
          "type": "table",
          "gridPos": {"h": 8, "w": 12, "x": 6, "y": 8},
          "targets": [
            {
              "expr": "ai_agent_tasks_completed_total{project=\"$PROJECT_NAME\"}",
              "format": "table"
            }
          ]
        },
        {
          "title": "Compliance Status",
          "type": "stat",
          "gridPos": {"h": 8, "w": 6, "x": 0, "y": 16},
          "targets": [
            {
              "expr": "compliance_score{project=\"$PROJECT_NAME\"}",
              "legendFormat": "Compliance Score"
            }
          ]
        },
        {
          "title": "Security Status",
          "type": "stat",
          "gridPos": {"h": 8, "w": 6, "x": 6, "y": 16},
          "targets": [
            {
              "expr": "security_score{project=\"$PROJECT_NAME\"}",
              "legendFormat": "Security Score"
            }
          ]
        }
      ]
    }
EOF

# Create scripts
echo "📜 Creating automation scripts..."
cat > $PROJECT_NAME/scripts/daily-standup.sh << 'EOF'
#!/bin/bash
# daily-standup.sh

PROJECT_NAME=$1
DATE=$(date +%Y-%m-%d)

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ./daily-standup.sh <project_name>"
    exit 1
fi

echo "=== Daily Standup - $PROJECT_NAME - $DATE ==="
echo ""

# Check AI agent status
echo "🤖 AI Agent Status:"
kubectl get pods -n ai-agents | grep $PROJECT_NAME || echo "No project-specific agents found"
echo ""

# Check project progress
echo "📊 Project Progress:"
kubectl get configmap -n ai-agents $PROJECT_NAME-progress -o yaml 2>/dev/null || echo "No progress data found"
echo ""

# Check compliance status
echo "🔒 Compliance Status:"
kubectl get configmap -n ai-agents $PROJECT_NAME-compliance -o yaml 2>/dev/null || echo "No compliance data found"
echo ""

# Check application health
echo "🏥 Application Health:"
kubectl get pods -n $PROJECT_NAME 2>/dev/null || echo "Application not deployed yet"
echo ""

# Team updates template
echo "👥 Team Updates:"
echo "Frontend Developer: [Update here]"
echo "Backend Developer: [Update here]"
echo "Compliance Specialist: [Update here]"
echo ""

# Next steps
echo "🎯 Next Steps:"
echo "- [ ] [Action item 1]"
echo "- [ ] [Action item 2]"
echo "- [ ] [Action item 3]"
echo ""

# Blockers
echo "🚨 Blockers:"
echo "- [ ] [Blocker 1]"
echo "- [ ] [Blocker 2]"
echo ""
EOF

cat > $PROJECT_NAME/scripts/manage-ai-agents.sh << 'EOF'
#!/bin/bash
# manage-ai-agents.sh

PROJECT_NAME=$1
ACTION=$2

if [ -z "$PROJECT_NAME" ] || [ -z "$ACTION" ]; then
    echo "Usage: ./manage-ai-agents.sh <project_name> <action>"
    echo "Actions: deploy, status, logs, scale, restart"
    exit 1
fi

case $ACTION in
    "deploy")
        echo "Deploying AI agents for $PROJECT_NAME..."
        kubectl apply -f ai-agents/
        kubectl apply -f ../../infra/ai-agents/services/
        echo "AI agents deployed successfully"
        ;;
    
    "status")
        echo "AI Agent Status for $PROJECT_NAME:"
        kubectl get pods -n ai-agents | grep $PROJECT_NAME
        kubectl get configmap -n ai-agents | grep $PROJECT_NAME
        ;;
    
    "logs")
        echo "AI Agent Logs for $PROJECT_NAME:"
        kubectl logs -n ai-agents deployment/ai-agent-orchestrator --tail=50
        kubectl logs -n ai-agents deployment/ai-agent-coding --tail=50
        kubectl logs -n ai-agents deployment/ai-agent-compliance --tail=50
        ;;
    
    "scale")
        echo "Scaling AI agents for $PROJECT_NAME..."
        kubectl scale deployment ai-agent-coding --replicas=5 -n ai-agents
        kubectl scale deployment ai-agent-testing --replicas=4 -n ai-agents
        kubectl scale deployment ai-agent-compliance --replicas=2 -n ai-agents
        echo "AI agents scaled successfully"
        ;;
    
    "restart")
        echo "Restarting AI agents for $PROJECT_NAME..."
        kubectl rollout restart deployment ai-agent-orchestrator -n ai-agents
        kubectl rollout restart deployment ai-agent-coding -n ai-agents
        kubectl rollout restart deployment ai-agent-testing -n ai-agents
        kubectl rollout restart deployment ai-agent-compliance -n ai-agents
        echo "AI agents restarted successfully"
        ;;
    
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
EOF

cat > $PROJECT_NAME/scripts/validate-compliance.sh << 'EOF'
#!/bin/bash
# validate-compliance.sh

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ./validate-compliance.sh <project_name>"
    exit 1
fi

echo "🔒 Validating Compliance for $PROJECT_NAME..."

# Check HIPAA compliance
echo "Checking HIPAA compliance..."
kubectl logs -n ai-agents deployment/ai-agent-compliance | grep -i hipaa

# Check FDA compliance
echo "Checking FDA 21 CFR Part 11 compliance..."
kubectl logs -n ai-agents deployment/ai-agent-compliance | grep -i "fda\|21 cfr"

# Check security posture
echo "Checking security posture..."
kubectl logs -n ai-agents deployment/ai-agent-security | grep -i "vulnerability\|security"

# Generate compliance report
cat > compliance-reports/$PROJECT_NAME-compliance-$(date +%Y%m%d).md << COMPLIANCE_EOF
# Compliance Report - $PROJECT_NAME - $(date +%Y-%m-%d)

## HIPAA Compliance
- [ ] Data encryption at rest
- [ ] Data encryption in transit
- [ ] Access controls
- [ ] Audit trails
- [ ] Data backup

## FDA 21 CFR Part 11 Compliance
- [ ] Electronic records integrity
- [ ] Electronic signatures
- [ ] Audit trails
- [ ] System validation

## Security Posture
- [ ] Vulnerability scanning
- [ ] Penetration testing
- [ ] Access control validation
- [ ] Data protection measures

## Recommendations
[Compliance recommendations and action items]
COMPLIANCE_EOF

echo "Compliance validation completed. Report saved to compliance-reports/$PROJECT_NAME-compliance-$(date +%Y%m%d).md"
EOF

# Make scripts executable
chmod +x $PROJECT_NAME/scripts/*.sh

# Create initial test structure
echo "🧪 Creating test structure..."
mkdir -p $PROJECT_NAME/tests/{unit,integration,e2e,compliance}

cat > $PROJECT_NAME/tests/unit/test_example.py << EOF
# Example unit test
import pytest
from unittest.mock import Mock, patch

def test_example():
    """Example unit test for $PROJECT_NAME"""
    assert True

def test_health_check():
    """Test health check endpoint"""
    # TODO: Implement health check test
    pass

def test_data_encryption():
    """Test data encryption functionality"""
    # TODO: Implement encryption test
    pass
EOF

cat > $PROJECT_NAME/tests/integration/test_api.py << EOF
# Example integration test
import pytest
import requests

class TestAPI:
    """Integration tests for $PROJECT_NAME API"""
    
    def test_health_endpoint(self):
        """Test health endpoint"""
        # TODO: Implement health endpoint test
        pass
    
    def test_patient_endpoints(self):
        """Test patient management endpoints"""
        # TODO: Implement patient endpoint tests
        pass
    
    def test_compliance_endpoints(self):
        """Test compliance validation endpoints"""
        # TODO: Implement compliance endpoint tests
        pass
EOF

cat > $PROJECT_NAME/tests/e2e/test_user_workflows.py << EOF
# Example E2E test
import pytest
from selenium import webdriver

class TestUserWorkflows:
    """End-to-end tests for $PROJECT_NAME user workflows"""
    
    def test_patient_registration_workflow(self):
        """Test complete patient registration workflow"""
        # TODO: Implement patient registration E2E test
        pass
    
    def test_compliance_reporting_workflow(self):
        """Test compliance reporting workflow"""
        # TODO: Implement compliance reporting E2E test
        pass
    
    def test_data_export_workflow(self):
        """Test data export workflow"""
        # TODO: Implement data export E2E test
        pass
EOF

cat > $PROJECT_NAME/tests/compliance/test_hipaa.py << EOF
# Example compliance test
import pytest

class TestHIPAACompliance:
    """HIPAA compliance tests for $PROJECT_NAME"""
    
    def test_data_encryption_at_rest(self):
        """Test data encryption at rest"""
        # TODO: Implement encryption at rest test
        pass
    
    def test_data_encryption_in_transit(self):
        """Test data encryption in transit"""
        # TODO: Implement encryption in transit test
        pass
    
    def test_access_controls(self):
        """Test access control implementation"""
        # TODO: Implement access control test
        pass
    
    def test_audit_trails(self):
        """Test audit trail functionality"""
        # TODO: Implement audit trail test
        pass
EOF

# Create package.json for frontend
cat > $PROJECT_NAME/frontend/package.json << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "1.0.0",
  "description": "Frontend for $PROJECT_NAME healthcare application",
  "main": "index.js",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint src --ext ts,tsx --fix"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "axios": "^1.3.0",
    "tailwindcss": "^3.2.0",
    "@headlessui/react": "^1.7.0",
    "@heroicons/react": "^2.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.27",
    "@types/react-dom": "^18.0.10",
    "@typescript-eslint/eslint-plugin": "^5.54.0",
    "@typescript-eslint/parser": "^5.54.0",
    "@vitejs/plugin-react": "^3.1.0",
    "eslint": "^8.35.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.3.4",
    "jest": "^29.4.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/jest-dom": "^5.16.5",
    "typescript": "^4.9.4",
    "vite": "^4.1.0"
  }
}
EOF

# Create requirements.txt for backend
cat > $PROJECT_NAME/backend/requirements.txt << EOF
# Backend requirements for $PROJECT_NAME
fastapi==0.95.0
uvicorn[standard]==0.21.1
pydantic==1.10.7
sqlalchemy==2.0.9
psycopg2-binary==2.9.6
alembic==1.10.4
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pytest==7.2.2
pytest-asyncio==0.21.0
httpx==0.24.0
python-dotenv==1.0.0
redis==4.5.4
celery==5.2.7
prometheus-client==0.16.0
structlog==23.1.0
EOF

echo ""
echo "✅ Project template created successfully for $PROJECT_NAME!"
echo ""
echo "📁 Project structure:"
echo "  $PROJECT_NAME/"
echo "  ├── README.md                    # Project overview and documentation"
echo "  ├── requirements/                # Business requirements and user stories"
echo "  ├── ai-agents/                   # AI agent configurations"
echo "  ├── team/                        # Team member configurations"
echo "  ├── config/                      # AI tools configuration files"
echo "  ├── frontend/                    # React/TypeScript frontend"
echo "  ├── backend/                     # Python/FastAPI backend"
echo "  ├── database/                    # Database schemas and migrations"
echo "  ├── deployment/                  # Kubernetes and monitoring configs"
echo "  ├── docs/                        # Documentation"
echo "  ├── scripts/                     # Automation scripts"
echo "  ├── tests/                       # Test suites"
echo "  └── config/                      # Configuration files"
echo ""
echo "🚀 Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. Customize requirements/user-stories.md"
echo "3. Update team/*.yaml with actual team member names"
echo "4. Configure AI tools in config/*"
echo "5. kubectl apply -f ai-agents/"
echo "6. ./scripts/daily-standup.sh $PROJECT_NAME"
echo ""
echo "🎯 AI Tools Integration:"
echo "  - Cursor IDE: Real-time coding assistance"
echo "  - Claude Code: Complex algorithm generation"
echo "  - GitHub Copilot: Pair programming support"
echo "  - CrewAI: Multi-agent orchestration"
echo ""
echo "🔒 Compliance Framework:"
echo "  - HIPAA compliance automation"
echo "  - FDA 21 CFR Part 11 validation"
echo "  - GDPR data protection"
echo "  - ISO 13485 quality management"
echo ""
echo "📊 Success Metrics:"
echo "  - Time to Market: < 8 weeks"
echo "  - Code Quality: > 90%"
echo "  - Test Coverage: > 95%"
echo "  - Compliance Score: 100%"
echo ""
echo "🎉 Ready to start AI-powered healthcare development!"
EOF 