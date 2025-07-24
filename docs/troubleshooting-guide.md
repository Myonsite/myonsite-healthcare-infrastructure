# Troubleshooting Guide

## 🎯 Overview

This troubleshooting guide provides solutions for common issues encountered when working with the MedinovAI AI-Managed Kubernetes Infrastructure. The guide covers problems related to installation, deployment, configuration, and operation of the system.

## 🔍 Diagnostic Tools

### System Health Check
```bash
# Comprehensive system health check
make health-check

# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check all pods across namespaces
kubectl get pods -A
```

### Resource Monitoring
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check resource quotas
kubectl get resourcequota -A
```

### Network Diagnostics
```bash
# Check network policies
kubectl get networkpolicies -A

# Test network connectivity
kubectl exec -it <pod-name> -- ping <target>

# Check DNS resolution
kubectl exec -it <pod-name> -- nslookup <service-name>
```

## 🚨 Common Issues

### Cluster Issues

#### Issue: Cluster Not Starting
**Symptoms**: `kind create cluster` fails or cluster nodes not ready

**Diagnosis**:
```bash
# Check Docker status
docker info
docker ps

# Check kind logs
kind export logs --name health-local

# Check system resources
free -h
df -h
```

**Solutions**:
1. **Docker Not Running**:
   ```bash
   # Start Docker Desktop
   open -a Docker  # macOS
   sudo systemctl start docker  # Linux
   ```

2. **Insufficient Resources**:
   ```bash
   # Increase Docker resources
   # Docker Desktop: Settings > Resources > Advanced
   # Increase CPU, Memory, and Disk space
   ```

3. **Port Conflicts**:
   ```bash
   # Check for port conflicts
   lsof -i :6443  # Kubernetes API
   lsof -i :3001  # Backstage
   lsof -i :8000  # CrewAI
   ```

#### Issue: Pods Stuck in Pending
**Symptoms**: Pods remain in `Pending` state

**Diagnosis**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl describe node <node-name>

# Check persistent volumes
kubectl get pv
kubectl get pvc -A
```

**Solutions**:
1. **Insufficient Resources**:
   ```bash
   # Scale down resource requests
   kubectl edit deployment <deployment-name> -n <namespace>
   # Reduce CPU and memory requests
   ```

2. **Storage Issues**:
   ```bash
   # Check storage class
   kubectl get storageclass
   
   # Create default storage class
   kubectl apply -f infra/storage-class-local.yaml
   ```

3. **Node Selector Issues**:
   ```bash
   # Check node labels
   kubectl get nodes --show-labels
   
   # Remove node selectors if not needed
   kubectl edit deployment <deployment-name> -n <namespace>
   ```

### Service Mesh Issues

#### Issue: Istio Installation Fails
**Symptoms**: Istio components not starting or mTLS not working

**Diagnosis**:
```bash
# Check Istio installation
istioctl version
istioctl analyze

# Check Istio pods
kubectl get pods -n istio-system

# Check Istio configuration
istioctl get all
```

**Solutions**:
1. **Installation Issues**:
   ```bash
   # Reinstall Istio
   make mesh-down
   make mesh-install
   make mesh-up
   ```

2. **mTLS Configuration**:
   ```bash
   # Check mTLS status
   istioctl authn tls-check
   
   # Apply mTLS policy
   kubectl apply -f infra/istio/mtls-policy.yaml
   ```

3. **Authorization Issues**:
   ```bash
   # Check authorization policies
   kubectl get authorizationpolicies -A
   
   # Apply default allow policy
   kubectl apply -f infra/istio/allow-policy.yaml
   ```

#### Issue: Service Communication Fails
**Symptoms**: Services cannot communicate with each other

**Diagnosis**:
```bash
# Check service endpoints
kubectl get endpoints -A

# Check service mesh proxies
istioctl proxy-status

# Test service connectivity
kubectl exec -it <pod-name> -- curl <service-url>
```

**Solutions**:
1. **Service Discovery Issues**:
   ```bash
   # Check DNS resolution
   kubectl exec -it <pod-name> -- nslookup <service-name>
   
   # Restart CoreDNS
   kubectl delete pod -l k8s-app=kube-dns -n kube-system
   ```

2. **Network Policy Issues**:
   ```bash
   # Check network policies
   kubectl get networkpolicies -A
   
   # Temporarily disable network policies
   kubectl delete networkpolicies --all -A
   ```

### CrewAI Platform Issues

#### Issue: CrewAI Pods Not Starting
**Symptoms**: CrewAI pods remain in `CrashLoopBackOff` or `Pending` state

**Diagnosis**:
```bash
# Check CrewAI pod status
kubectl get pods -n crewai

# Check pod logs
kubectl logs -l app=crewai-app -n crewai

# Check pod events
kubectl describe pod -l app=crewai-app -n crewai
```

**Solutions**:
1. **Database Connection Issues**:
   ```bash
   # Check PostgreSQL status
   kubectl get pods -n crewai -l app=crewai-postgresql
   
   # Check database logs
   kubectl logs -l app=crewai-postgresql -n crewai
   
   # Test database connection
   kubectl exec -it <crewai-pod> -- psql -h crewai-postgresql -U crewai -d crewai
   ```

2. **Configuration Issues**:
   ```bash
   # Check configuration
   kubectl get configmap crewai-config -n crewai -o yaml
   
   # Update configuration
   kubectl apply -f infra/crewai/configmap.yaml
   ```

3. **Resource Issues**:
   ```bash
   # Check resource limits
   kubectl describe pod -l app=crewai-app -n crewai
   
   # Increase resource limits
   kubectl edit deployment crewai-app -n crewai
   ```

#### Issue: CrewAI API Not Accessible
**Symptoms**: Cannot access CrewAI API endpoints

**Diagnosis**:
```bash
# Check service status
kubectl get svc -n crewai

# Check port forwarding
kubectl port-forward svc/crewai-app 8000:8000 -n crewai

# Test API endpoints
curl http://localhost:8000/health
curl http://localhost:8000/agents
```

**Solutions**:
1. **Service Issues**:
   ```bash
   # Restart CrewAI service
   kubectl rollout restart deployment crewai-app -n crewai
   
   # Check service endpoints
   kubectl get endpoints crewai-app -n crewai
   ```

2. **Port Forwarding Issues**:
   ```bash
   # Kill existing port forwards
   pkill -f "kubectl port-forward"
   
   # Start new port forward
   kubectl port-forward svc/crewai-app 8000:8000 -n crewai
   ```

### Backstage Issues

#### Issue: Backstage Portal Not Loading
**Symptoms**: Cannot access Backstage portal or portal shows errors

**Diagnosis**:
```bash
# Check Backstage pod status
kubectl get pods -n infrastructure -l app=backstage

# Check Backstage logs
kubectl logs -l app=backstage -n infrastructure

# Check service status
kubectl get svc backstage -n infrastructure
```

**Solutions**:
1. **Pod Issues**:
   ```bash
   # Restart Backstage
   kubectl rollout restart deployment backstage -n infrastructure
   
   # Check pod events
   kubectl describe pod -l app=backstage -n infrastructure
   ```

2. **Configuration Issues**:
   ```bash
   # Check app-config
   kubectl get configmap backstage-app-config -n infrastructure -o yaml
   
   # Update configuration
   kubectl apply -f infra/clusters/local/backstage-simple.yaml
   ```

3. **Database Issues**:
   ```bash
   # Check database connection
   kubectl exec -it <backstage-pod> -- pg_isready -h backstage-postgresql
   
   # Restart database
   kubectl rollout restart statefulset backstage-postgresql -n infrastructure
   ```

### Monitoring Issues

#### Issue: Prometheus Not Collecting Metrics
**Symptoms**: No metrics visible in Grafana or Prometheus

**Diagnosis**:
```bash
# Check Prometheus status
kubectl get pods -n monitoring -l app=prometheus

# Check Prometheus logs
kubectl logs -l app=prometheus -n monitoring

# Check service monitors
kubectl get servicemonitors -A
```

**Solutions**:
1. **Prometheus Configuration**:
   ```bash
   # Check Prometheus config
   kubectl get configmap prometheus-config -n monitoring -o yaml
   
   # Reload Prometheus configuration
   kubectl rollout restart deployment prometheus -n monitoring
   ```

2. **Service Monitor Issues**:
   ```bash
   # Check service monitor status
   kubectl get servicemonitors -A
   
   # Apply service monitors
   kubectl apply -f infra/monitoring/servicemonitors/
   ```

#### Issue: Grafana Dashboards Not Loading
**Symptoms**: Grafana accessible but dashboards show no data

**Diagnosis**:
```bash
# Check Grafana status
kubectl get pods -n monitoring -l app=grafana

# Check Grafana logs
kubectl logs -l app=grafana -n monitoring

# Check data source configuration
kubectl get configmap grafana-datasources -n monitoring -o yaml
```

**Solutions**:
1. **Data Source Issues**:
   ```bash
   # Update data source configuration
   kubectl apply -f infra/monitoring/grafana-datasources.yaml
   
   # Restart Grafana
   kubectl rollout restart deployment grafana -n monitoring
   ```

2. **Dashboard Issues**:
   ```bash
   # Apply dashboard configurations
   kubectl apply -f infra/monitoring/grafana-dashboards/
   
   # Check dashboard status
   kubectl get configmap -l grafana_dashboard -n monitoring
   ```

### Security Issues

#### Issue: mTLS Authentication Fails
**Symptoms**: Service-to-service communication fails with TLS errors

**Diagnosis**:
```bash
# Check mTLS status
istioctl authn tls-check

# Check certificate status
kubectl get secrets -n istio-system

# Check authorization policies
kubectl get authorizationpolicies -A
```

**Solutions**:
1. **Certificate Issues**:
   ```bash
   # Regenerate certificates
   kubectl delete secret istio-ca-secret -n istio-system
   istioctl install --set profile=demo
   ```

2. **Authorization Issues**:
   ```bash
   # Apply permissive authorization
   kubectl apply -f infra/istio/permissive-policy.yaml
   
   # Check policy status
   istioctl analyze
   ```

#### Issue: Network Policies Blocking Traffic
**Symptoms**: Pods cannot communicate due to network policies

**Diagnosis**:
```bash
# Check network policies
kubectl get networkpolicies -A

# Check policy details
kubectl describe networkpolicy <policy-name> -n <namespace>

# Test connectivity
kubectl exec -it <pod-name> -- curl <target>
```

**Solutions**:
1. **Policy Issues**:
   ```bash
   # Temporarily disable policies
   kubectl delete networkpolicies --all -A
   
   # Apply correct policies
   kubectl apply -f infra/network-policies/
   ```

2. **Label Issues**:
   ```bash
   # Check pod labels
   kubectl get pods --show-labels -A
   
   # Update pod labels
   kubectl label pod <pod-name> app=<app-name> -n <namespace>
   ```

### Compliance Issues

#### Issue: Compliance Checks Failing
**Symptoms**: Compliance validation reports failures

**Diagnosis**:
```bash
# Run compliance check
make compliance-test

# Check compliance status
kubectl get compliancechecks -A

# Check audit logs
kubectl logs -l app=compliance-agent -n compliance
```

**Solutions**:
1. **Policy Violations**:
   ```bash
   # Check policy violations
   kubectl get policyviolations -A
   
   # Fix violations
   kubectl apply -f infra/compliance/fixes/
   ```

2. **Audit Issues**:
   ```bash
   # Check audit configuration
   kubectl get auditpolicy -A
   
   # Update audit policy
   kubectl apply -f infra/audit/audit-policy.yaml
   ```

## 🔧 Advanced Troubleshooting

### Performance Issues

#### High Resource Usage
**Symptoms**: System slow, high CPU/memory usage

**Diagnosis**:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check resource limits
kubectl describe nodes
kubectl describe pods -A
```

**Solutions**:
1. **Scale Resources**:
   ```bash
   # Scale down deployments
   kubectl scale deployment <deployment> --replicas=1 -n <namespace>
   
   # Increase node resources
   # Add more nodes to cluster
   ```

2. **Optimize Configurations**:
   ```bash
   # Update resource limits
   kubectl edit deployment <deployment> -n <namespace>
   
   # Apply resource quotas
   kubectl apply -f infra/resource-quotas/
   ```

#### Slow Response Times
**Symptoms**: API calls slow, high latency

**Diagnosis**:
```bash
# Check service mesh metrics
istioctl dashboard grafana

# Check application metrics
kubectl exec -it <pod> -- curl localhost:9090/metrics

# Check network latency
kubectl exec -it <pod> -- ping <service>
```

**Solutions**:
1. **Network Optimization**:
   ```bash
   # Check network policies
   kubectl get networkpolicies -A
   
   # Optimize routing
   istioctl analyze
   ```

2. **Application Optimization**:
   ```bash
   # Check application logs
   kubectl logs -l app=<app> -n <namespace>
   
   # Optimize application configuration
   kubectl edit deployment <deployment> -n <namespace>
   ```

### Data Issues

#### Database Connection Problems
**Symptoms**: Applications cannot connect to databases

**Diagnosis**:
```bash
# Check database pods
kubectl get pods -l app=postgresql -A

# Check database logs
kubectl logs -l app=postgresql -A

# Test database connection
kubectl exec -it <pod> -- psql -h <host> -U <user> -d <database>
```

**Solutions**:
1. **Database Issues**:
   ```bash
   # Restart database
   kubectl rollout restart statefulset <database> -n <namespace>
   
   # Check persistent volumes
   kubectl get pv
   kubectl get pvc -A
   ```

2. **Connection Issues**:
   ```bash
   # Check service endpoints
   kubectl get endpoints <service> -n <namespace>
   
   # Update connection strings
   kubectl edit configmap <config> -n <namespace>
   ```

#### Data Loss Issues
**Symptoms**: Data missing or corrupted

**Diagnosis**:
```bash
# Check backup status
kubectl get backups -A

# Check persistent volumes
kubectl get pv
kubectl get pvc -A

# Check data integrity
kubectl exec -it <pod> -- pg_dump <database>
```

**Solutions**:
1. **Restore from Backup**:
   ```bash
   # List available backups
   kubectl get backups -A
   
   # Restore from backup
   kubectl apply -f backup-restore.yaml
   ```

2. **Volume Issues**:
   ```bash
   # Check volume status
   kubectl describe pv <volume>
   
   # Recreate volume
   kubectl delete pvc <claim> -n <namespace>
   kubectl apply -f pvc.yaml
   ```

## 📊 Monitoring and Alerting

### Setting Up Alerts
```bash
# Create alert rules
kubectl apply -f infra/monitoring/alert-rules/

# Check alert status
kubectl get prometheusrules -A

# Test alerts
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
```

### Log Analysis
```bash
# Collect logs
kubectl logs -l app=<app> -n <namespace> > app.log

# Analyze logs
grep ERROR app.log
grep WARN app.log

# Search logs
kubectl logs -l app=<app> -n <namespace> | grep <pattern>
```

## 🆘 Emergency Procedures

### Emergency Stop
```bash
# Stop all AI agents
kubectl scale deployment --all --replicas=0 -A

# Stop all services
kubectl delete deployment --all -A

# Stop cluster
make dev-down
```

### Emergency Recovery
```bash
# Restart cluster
make dev-up

# Restore from backup
make restore-backup

# Verify system health
make health-check
```

### Emergency Contact
- **Infrastructure Team**: infrastructure@medinovai.com
- **Security Team**: security@medinovai.com
- **Compliance Team**: compliance@medinovai.com

## 📚 Additional Resources

### Documentation
- **Architecture Overview**: [docs/architecture-overview.md](architecture-overview.md)
- **Installation Guide**: [docs/installation-guide.md](installation-guide.md)
- **API Reference**: [docs/api-reference.md](api-reference.md)

### External Resources
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Istio Documentation**: https://istio.io/docs/
- **CrewAI Documentation**: https://docs.crewai.com/

### Community Support
- **GitHub Issues**: Report issues on GitHub
- **Discord Community**: Join community discussions
- **Stack Overflow**: Search for solutions

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Maintainer**: MedinovAI Infrastructure Team 