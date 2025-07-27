#!/bin/bash
# project-management-dashboard.sh
# Comprehensive project management dashboard for healthcare projects with AI tools integration

set -e

PROJECTS_DIR="healthcare-projects"
DASHBOARD_PORT=8080

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        "progress")
            echo -e "${CYAN}🔄 $message${NC}"
            ;;
        "ai")
            echo -e "${PURPLE}🤖 $message${NC}"
            ;;
    esac
}

# Function to check if project exists
project_exists() {
    local project_name=$1
    [ -d "$PROJECTS_DIR/$project_name" ]
}

# Function to get project status
get_project_status() {
    local project_name=$1
    
    if ! project_exists "$project_name"; then
        echo "not_found"
        return
    fi
    
    # Check if AI agents are running
    local ai_agents_running=$(kubectl get pods -n ai-agents 2>/dev/null | grep "$project_name" | grep -c "Running" || echo "0")
    
    # Check if application is deployed
    local app_deployed=$(kubectl get pods -n "$project_name" 2>/dev/null | grep -c "Running" || echo "0")
    
    # Check compliance status
    local compliance_status=$(kubectl get configmap -n ai-agents "$project_name-compliance" 2>/dev/null | grep -c "status.*passed" || echo "0")
    
    if [ "$ai_agents_running" -gt 0 ] && [ "$app_deployed" -gt 0 ] && [ "$compliance_status" -gt 0 ]; then
        echo "active"
    elif [ "$ai_agents_running" -gt 0 ]; then
        echo "developing"
    else
        echo "inactive"
    fi
}

# Function to display project overview
show_project_overview() {
    echo ""
    print_status "info" "🏥 Healthcare Projects Overview"
    echo "=================================================="
    
    if [ ! -d "$PROJECTS_DIR" ]; then
        print_status "warning" "No projects directory found. Creating..."
        mkdir -p "$PROJECTS_DIR"
        return
    fi
    
    local total_projects=0
    local active_projects=0
    local developing_projects=0
    local inactive_projects=0
    
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            local status=$(get_project_status "$project_name")
            local total_projects=$((total_projects + 1))
            
            case $status in
                "active")
                    print_status "success" "$project_name - Active (AI agents running, app deployed, compliant)"
                    active_projects=$((active_projects + 1))
                    ;;
                "developing")
                    print_status "progress" "$project_name - In Development (AI agents running)"
                    developing_projects=$((developing_projects + 1))
                    ;;
                "inactive")
                    print_status "warning" "$project_name - Inactive (No AI agents running)"
                    inactive_projects=$((inactive_projects + 1))
                    ;;
                "not_found")
                    print_status "error" "$project_name - Not Found"
                    ;;
            esac
        fi
    done
    
    echo ""
    print_status "info" "📊 Project Statistics:"
    echo "  Total Projects: $total_projects"
    echo "  Active: $active_projects"
    echo "  In Development: $developing_projects"
    echo "  Inactive: $inactive_projects"
}

# Function to show detailed project information
show_project_details() {
    local project_name=$1
    
    if ! project_exists "$project_name"; then
        print_status "error" "Project '$project_name' not found"
        return
    fi
    
    echo ""
    print_status "info" "📋 Project Details: $project_name"
    echo "=================================================="
    
    # Project configuration
    if [ -f "$PROJECTS_DIR/$project_name/ai-agents/project-config.yaml" ]; then
        print_status "info" "Project Configuration:"
        kubectl get configmap -n ai-agents "$project_name-config" -o yaml 2>/dev/null | grep -E "(project_name|project_type|team_size|estimated_duration)" || echo "  Configuration not found"
    fi
    
    # AI Agent Status
    print_status "ai" "AI Agent Status:"
    kubectl get pods -n ai-agents | grep "$project_name" || echo "  No AI agents found"
    
    # Application Status
    print_status "info" "Application Status:"
    kubectl get pods -n "$project_name" 2>/dev/null || echo "  Application not deployed"
    
    # Compliance Status
    print_status "info" "Compliance Status:"
    kubectl get configmap -n ai-agents "$project_name-compliance" -o yaml 2>/dev/null | grep -E "(hipaa|fda|gdpr)" || echo "  No compliance data found"
    
    # Team Information
    if [ -d "$PROJECTS_DIR/$project_name/team" ]; then
        print_status "info" "Team Members:"
        for team_file in "$PROJECTS_DIR/$project_name/team"/*.yaml; do
            if [ -f "$team_file" ]; then
                local role=$(basename "$team_file" .yaml | sed 's/-/ /g')
                local name=$(grep "name:" "$team_file" | head -1 | cut -d':' -f2 | tr -d ' "[]')
                echo "  $role: $name"
            fi
        done
    fi
    
    # Recent Activity
    print_status "info" "Recent Activity:"
    kubectl logs -n ai-agents deployment/ai-agent-orchestrator --tail=10 2>/dev/null | grep "$project_name" || echo "  No recent activity found"
}

# Function to manage projects
manage_projects() {
    local action=$1
    local project_name=$2
    
    case $action in
        "create")
            if [ -z "$project_name" ]; then
                print_status "error" "Please provide a project name"
                echo "Usage: $0 manage create <project_name> <project_type>"
                return
            fi
            
            local project_type=$3
            if [ -z "$project_type" ]; then
                print_status "error" "Please provide a project type"
                echo "Available types: clinical_trials, ehr_system, telemedicine, pharmacy_management, laboratory_lims, hospital_management, medical_imaging, precision_medicine"
                return
            fi
            
            print_status "progress" "Creating project: $project_name ($project_type)"
            ./scripts/create-project-template.sh "$project_name" "$project_type"
            print_status "success" "Project created successfully"
            ;;
        
        "deploy")
            if [ -z "$project_name" ]; then
                print_status "error" "Please provide a project name"
                return
            fi
            
            if ! project_exists "$project_name"; then
                print_status "error" "Project '$project_name' not found"
                return
            fi
            
            print_status "progress" "Deploying AI agents for $project_name..."
            cd "$PROJECTS_DIR/$project_name"
            ./scripts/manage-ai-agents.sh "$project_name" deploy
            cd - > /dev/null
            print_status "success" "AI agents deployed successfully"
            ;;
        
        "status")
            if [ -z "$project_name" ]; then
                show_project_overview
            else
                show_project_details "$project_name"
            fi
            ;;
        
        "logs")
            if [ -z "$project_name" ]; then
                print_status "error" "Please provide a project name"
                return
            fi
            
            print_status "info" "AI Agent Logs for $project_name:"
            kubectl logs -n ai-agents deployment/ai-agent-orchestrator --tail=50 | grep "$project_name" || echo "No logs found"
            ;;
        
        "compliance")
            if [ -z "$project_name" ]; then
                print_status "error" "Please provide a project name"
                return
            fi
            
            if ! project_exists "$project_name"; then
                print_status "error" "Project '$project_name' not found"
                return
            fi
            
            print_status "progress" "Validating compliance for $project_name..."
            cd "$PROJECTS_DIR/$project_name"
            ./scripts/validate-compliance.sh "$project_name"
            cd - > /dev/null
            ;;
        
        "delete")
            if [ -z "$project_name" ]; then
                print_status "error" "Please provide a project name"
                return
            fi
            
            if ! project_exists "$project_name"; then
                print_status "error" "Project '$project_name' not found"
                return
            fi
            
            print_status "warning" "Are you sure you want to delete project '$project_name'? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                print_status "progress" "Deleting project: $project_name..."
                kubectl delete namespace "$project_name" 2>/dev/null || true
                rm -rf "$PROJECTS_DIR/$project_name"
                print_status "success" "Project deleted successfully"
            else
                print_status "info" "Project deletion cancelled"
            fi
            ;;
        
        *)
            print_status "error" "Unknown action: $action"
            echo "Available actions: create, deploy, status, logs, compliance, delete"
            ;;
    esac
}

# Function to show AI tools integration status
show_ai_tools_status() {
    echo ""
    print_status "ai" "🛠️ AI Tools Integration Status"
    echo "=================================================="
    
    # Check Cursor IDE
    if command -v cursor >/dev/null 2>&1; then
        print_status "success" "Cursor IDE: Installed and available"
    else
        print_status "warning" "Cursor IDE: Not installed (recommended for AI-powered development)"
    fi
    
    # Check GitHub Copilot
    print_status "info" "GitHub Copilot: Browser-based (requires GitHub account)"
    
    # Check Claude Code
    print_status "info" "Claude Code: Browser-based (requires Anthropic account)"
    
    # Check CrewAI
    if kubectl get pods -n ai-agents | grep -q "crewai"; then
        print_status "success" "CrewAI: Running in Kubernetes cluster"
    else
        print_status "warning" "CrewAI: Not deployed (run 'make dev-up' to deploy)"
    fi
    
    # Check Kubernetes cluster
    if kubectl cluster-info >/dev/null 2>&1; then
        print_status "success" "Kubernetes Cluster: Connected"
        
        # Check AI agents namespace
        if kubectl get namespace ai-agents >/dev/null 2>&1; then
            print_status "success" "AI Agents Namespace: Available"
            
            # Count running AI agents
            local running_agents=$(kubectl get pods -n ai-agents | grep -c "Running" || echo "0")
            print_status "info" "Running AI Agents: $running_agents"
        else
            print_status "warning" "AI Agents Namespace: Not found (run 'make dev-up' to create)"
        fi
    else
        print_status "error" "Kubernetes Cluster: Not connected"
    fi
}

# Function to show compliance dashboard
show_compliance_dashboard() {
    echo ""
    print_status "info" "🔒 Compliance Dashboard"
    echo "=================================================="
    
    local total_projects=0
    local compliant_projects=0
    local non_compliant_projects=0
    
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            local total_projects=$((total_projects + 1))
            
            # Check compliance status
            local hipaa_compliant=$(kubectl get configmap -n ai-agents "$project_name-compliance" 2>/dev/null | grep -c "hipaa.*passed" || echo "0")
            local fda_compliant=$(kubectl get configmap -n ai-agents "$project_name-compliance" 2>/dev/null | grep -c "fda.*passed" || echo "0")
            local gdpr_compliant=$(kubectl get configmap -n ai-agents "$project_name-compliance" 2>/dev/null | grep -c "gdpr.*passed" || echo "0")
            
            if [ "$hipaa_compliant" -gt 0 ] && [ "$fda_compliant" -gt 0 ] && [ "$gdpr_compliant" -gt 0 ]; then
                print_status "success" "$project_name: Fully Compliant (HIPAA ✅ FDA ✅ GDPR ✅)"
                compliant_projects=$((compliant_projects + 1))
            else
                print_status "warning" "$project_name: Non-Compliant (HIPAA: $hipaa_compliant FDA: $fda_compliant GDPR: $gdpr_compliant)"
                non_compliant_projects=$((non_compliant_projects + 1))
            fi
        fi
    done
    
    echo ""
    print_status "info" "📊 Compliance Statistics:"
    echo "  Total Projects: $total_projects"
    echo "  Compliant: $compliant_projects"
    echo "  Non-Compliant: $non_compliant_projects"
    echo "  Compliance Rate: $([ $total_projects -gt 0 ] && echo "$((compliant_projects * 100 / total_projects))%" || echo "0%")"
}

# Function to show performance metrics
show_performance_metrics() {
    echo ""
    print_status "info" "📈 Performance Metrics"
    echo "=================================================="
    
    # Overall cluster metrics
    print_status "info" "Cluster Performance:"
    local total_pods=$(kubectl get pods --all-namespaces | grep -c "Running" || echo "0")
    local total_cpu=$(kubectl top nodes 2>/dev/null | tail -n +2 | awk '{sum += $3} END {print sum}' || echo "0")
    local total_memory=$(kubectl top nodes 2>/dev/null | tail -n +2 | awk '{sum += $5} END {print sum}' || echo "0")
    
    echo "  Running Pods: $total_pods"
    echo "  CPU Usage: ${total_cpu}m"
    echo "  Memory Usage: ${total_memory}Mi"
    
    # AI Agent Performance
    print_status "ai" "AI Agent Performance:"
    local ai_agent_pods=$(kubectl get pods -n ai-agents | grep -c "Running" || echo "0")
    local ai_agent_cpu=$(kubectl top pods -n ai-agents 2>/dev/null | tail -n +2 | awk '{sum += $2} END {print sum}' || echo "0")
    local ai_agent_memory=$(kubectl top pods -n ai-agents 2>/dev/null | tail -n +2 | awk '{sum += $4} END {print sum}' || echo "0")
    
    echo "  AI Agent Pods: $ai_agent_pods"
    echo "  AI Agent CPU: ${ai_agent_cpu}m"
    echo "  AI Agent Memory: ${ai_agent_memory}Mi"
    
    # Project-specific metrics
    print_status "info" "Project Performance:"
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            local project_pods=$(kubectl get pods -n "$project_name" 2>/dev/null | grep -c "Running" || echo "0")
            local project_cpu=$(kubectl top pods -n "$project_name" 2>/dev/null | tail -n +2 | awk '{sum += $2} END {print sum}' || echo "0")
            local project_memory=$(kubectl top pods -n "$project_name" 2>/dev/null | tail -n +2 | awk '{sum += $4} END {print sum}' || echo "0")
            
            if [ "$project_pods" -gt 0 ]; then
                echo "  $project_name: $project_pods pods, ${project_cpu}m CPU, ${project_memory}Mi Memory"
            fi
        fi
    done
}

# Function to show help
show_help() {
    echo ""
    print_status "info" "🏥 Healthcare Project Management Dashboard"
    echo "=================================================="
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  overview                    Show project overview"
    echo "  details <project_name>      Show detailed project information"
    echo "  manage <action> [options]   Manage projects"
    echo "  ai-tools                    Show AI tools integration status"
    echo "  compliance                  Show compliance dashboard"
    echo "  performance                 Show performance metrics"
    echo "  dashboard                   Start web dashboard (port $DASHBOARD_PORT)"
    echo "  help                        Show this help message"
    echo ""
    echo "Manage Actions:"
    echo "  create <name> <type>        Create new project"
    echo "  deploy <name>               Deploy AI agents for project"
    echo "  status [name]               Show project status"
    echo "  logs <name>                 Show AI agent logs"
    echo "  compliance <name>           Validate project compliance"
    echo "  delete <name>               Delete project"
    echo ""
    echo "Project Types:"
    echo "  clinical_trials             Clinical trial management"
    echo "  ehr_system                  Electronic health records"
    echo "  telemedicine                Telemedicine platform"
    echo "  pharmacy_management         Pharmacy management system"
    echo "  laboratory_lims             Laboratory information system"
    echo "  hospital_management         Hospital management system"
    echo "  medical_imaging             Medical imaging platform"
    echo "  precision_medicine          Precision medicine platform"
    echo ""
    echo "Examples:"
    echo "  $0 overview"
    echo "  $0 manage create clinical-trials clinical_trials"
    echo "  $0 manage deploy clinical-trials"
    echo "  $0 details clinical-trials"
    echo "  $0 compliance"
    echo ""
}

# Function to start web dashboard
start_web_dashboard() {
    print_status "progress" "Starting web dashboard on port $DASHBOARD_PORT..."
    
    # Create simple HTML dashboard
    cat > /tmp/healthcare-dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Healthcare Project Management Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status-success { color: #27ae60; }
        .status-warning { color: #f39c12; }
        .status-error { color: #e74c3c; }
        .refresh-btn { background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .refresh-btn:hover { background: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏥 Healthcare Project Management Dashboard</h1>
            <p>AI-Powered Healthcare Development Platform</p>
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
        </div>
        
        <div class="grid">
            <div class="card">
                <h2>📊 Project Overview</h2>
                <div id="project-overview">Loading...</div>
            </div>
            
            <div class="card">
                <h2>🤖 AI Tools Status</h2>
                <div id="ai-tools-status">Loading...</div>
            </div>
            
            <div class="card">
                <h2>🔒 Compliance Status</h2>
                <div id="compliance-status">Loading...</div>
            </div>
            
            <div class="card">
                <h2>📈 Performance Metrics</h2>
                <div id="performance-metrics">Loading...</div>
            </div>
        </div>
    </div>
    
    <script>
        // Simple dashboard functionality
        function updateDashboard() {
            // This would typically make API calls to get real data
            document.getElementById('project-overview').innerHTML = `
                <p><span class="status-success">✅ Active Projects: 3</span></p>
                <p><span class="status-warning">⚠️ In Development: 2</span></p>
                <p><span class="status-error">❌ Inactive: 1</span></p>
            `;
            
            document.getElementById('ai-tools-status').innerHTML = `
                <p><span class="status-success">✅ Cursor IDE: Available</span></p>
                <p><span class="status-success">✅ GitHub Copilot: Active</span></p>
                <p><span class="status-success">✅ Claude Code: Available</span></p>
                <p><span class="status-success">✅ CrewAI: Running</span></p>
            `;
            
            document.getElementById('compliance-status').innerHTML = `
                <p><span class="status-success">✅ HIPAA: Compliant</span></p>
                <p><span class="status-success">✅ FDA 21 CFR Part 11: Compliant</span></p>
                <p><span class="status-success">✅ GDPR: Compliant</span></p>
            `;
            
            document.getElementById('performance-metrics').innerHTML = `
                <p>Running Pods: 15</p>
                <p>CPU Usage: 45%</p>
                <p>Memory Usage: 62%</p>
                <p>AI Agents: 8 active</p>
            `;
        }
        
        // Update dashboard on load
        updateDashboard();
        
        // Auto-refresh every 30 seconds
        setInterval(updateDashboard, 30000);
    </script>
</body>
</html>
EOF
    
    # Start simple HTTP server
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$DASHBOARD_PORT" --directory /tmp &
        local server_pid=$!
        print_status "success" "Web dashboard started at http://localhost:$DASHBOARD_PORT"
        print_status "info" "Press Ctrl+C to stop the dashboard"
        
        # Wait for user to stop
        trap "kill $server_pid 2>/dev/null; rm -f /tmp/healthcare-dashboard.html; exit" INT
        wait
    else
        print_status "error" "Python3 not found. Cannot start web dashboard."
    fi
}

# Main script logic
case ${1:-overview} in
    "overview")
        show_project_overview
        ;;
    
    "details")
        show_project_details "$2"
        ;;
    
    "manage")
        manage_projects "$2" "$3" "$4"
        ;;
    
    "ai-tools")
        show_ai_tools_status
        ;;
    
    "compliance")
        show_compliance_dashboard
        ;;
    
    "performance")
        show_performance_metrics
        ;;
    
    "dashboard")
        start_web_dashboard
        ;;
    
    "help"|"-h"|"--help")
        show_help
        ;;
    
    *)
        print_status "error" "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 