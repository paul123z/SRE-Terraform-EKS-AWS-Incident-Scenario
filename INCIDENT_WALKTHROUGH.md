# SRE Incident Walkthrough Guide

This document provides a step-by-step walkthrough of how to simulate, detect, diagnose, and resolve incidents in the SRE demo environment.

## 🚨 Incident Scenario: Application Health Check Failure

### Scenario Overview
The application's health check endpoint begins returning 503 errors, causing Kubernetes to restart pods repeatedly. This simulates a common production issue where an application becomes unresponsive.

### Timeline
1. **T+0**: Application running normally
2. **T+1**: Health check failure triggered
3. **T+2**: Kubernetes detects failure, restarts pods
4. **T+3**: Monitoring alerts fire
5. **T+4**: Investigation begins
6. **T+5**: Root cause identified
7. **T+6**: Resolution applied
8. **T+7**: Verification and recovery

## 🔍 Step-by-Step Walkthrough

### Step 1: Initial State Verification

```bash
# Check application status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Check application health
curl http://<service-url>/health

# Check service endpoints
kubectl get endpoints sre-demo-app

# Check HPA status
kubectl get hpa
```

**Expected Output**: All pods running, health checks passing, endpoints healthy.

### Step 2: Trigger the Incident

```bash
# Simulate health check failure
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "health_failure"}'
```

### Step 3: Detection Phase

#### 3.1 Monitor Pod Status
```bash
# Watch pod status changes
kubectl get pods -l app.kubernetes.io/name=sre-demo-app -w

# Check pod events
kubectl describe pod <pod-name>
```

**What to Look For**:
- Pods entering `CrashLoopBackOff` state
- Liveness probe failures
- Pod restart counts increasing

#### 3.2 Check Application Logs
```bash
# Get recent logs
kubectl logs -l app.kubernetes.io/name=sre-demo-app --tail=50

# Follow logs in real-time
kubectl logs -l app.kubernetes.io/name=sre-demo-app -f
```

**What to Look For**:
- Health check endpoint returning 503
- Application error messages
- Unusual patterns in logs

#### 3.3 Check Monitoring Dashboards
```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Navigate to**: http://localhost:3000
- **Username**: admin
- **Password**: <GRAFANA_PASSWORD>

**Check These Dashboards**:
- Application Health Status
- Pod Restart Count
- Error Rate Metrics

### Step 4: Diagnosis Phase

#### 4.1 Investigate Health Check Endpoint
```bash
# Test health endpoint directly
curl -v http://<service-url>/health

# Check from within a pod
kubectl exec -it <pod-name> -- curl http://localhost:3000/health
```

#### 4.2 Check Application Configuration
```bash
# Check deployment configuration
kubectl describe deployment sre-demo-app

# Check environment variables
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].env}'
```

#### 4.3 Analyze Resource Usage
```bash
# Check resource usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app

# Check resource limits
kubectl describe pod <pod-name> | grep -A 10 "Limits:"
```

### Step 5: Root Cause Analysis

**Common Findings**:
1. **Application Logic Issue**: Health check endpoint returning 503
2. **Resource Constraints**: CPU/Memory limits causing timeouts
3. **Configuration Error**: Incorrect health check configuration
4. **Dependency Failure**: External service dependency down

**In This Scenario**: The application is intentionally returning 503 from the health endpoint due to the failure mode being set to "health_failure".

### Step 6: Resolution Phase

#### 6.1 Immediate Fix
```bash
# Reset the failure mode
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "none"}'
```

#### 6.2 Verify Recovery
```bash
# Check health endpoint
curl http://<service-url>/health

# Monitor pod status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Check if pods are stable
kubectl rollout status deployment sre-demo-app
```

#### 6.3 Alternative Resolution Methods

**Method 1: Restart Application**
```bash
kubectl rollout restart deployment sre-demo-app
```

**Method 2: Scale Up**
```bash
kubectl scale deployment sre-demo-app --replicas=3
```

**Method 3: Update Configuration**
```bash
# Update deployment with new configuration
kubectl patch deployment sre-demo-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"sre-demo-app","env":[{"name":"FAILURE_MODE","value":"none"}]}]}}}}'
```

### Step 7: Verification and Monitoring

#### 7.1 Verify Application Health
```bash
# Check all endpoints
curl http://<service-url>/
curl http://<service-url>/health
curl http://<service-url>/api/data

# Monitor for stability
kubectl get pods -l app.kubernetes.io/name=sre-demo-app -w
```

#### 7.2 Check Monitoring Metrics
- Verify health status is green in Grafana
- Confirm no new pod restarts
- Check error rates are back to normal

#### 7.3 Long-term Monitoring
```bash
# Set up continuous monitoring
watch -n 5 'kubectl get pods -l app.kubernetes.io/name=sre-demo-app'

# Monitor logs for any new issues
kubectl logs -l app.kubernetes.io/name=sre-demo-app -f
```

## 🚨 Other Incident Scenarios

### Scenario 2: Memory Leak
```bash
# Trigger memory leak
curl -X POST http://<service-url>/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": true}'

# Monitor memory usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app

# Resolution
curl -X POST http://<service-url>/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": false}'
```

### Scenario 3: CPU Stress
```bash
# Trigger CPU stress
curl -X POST http://<service-url>/api/cpu-stress \
  -H "Content-Type: application/json" \
  -d '{"enable": true}'

# Monitor CPU usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app

# Resolution
curl -X POST http://<service-url>/api/cpu-stress \
  -H "Content-Type: application/json" \
  -d '{"enable": false}'
```

### Scenario 4: Slow Response
```bash
# Trigger slow response
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "slow_response"}'

# Test response time
time curl http://<service-url>/health

# Resolution
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "none"}'
```

## 📊 Key Metrics to Monitor

### Application Metrics
- **Health Check Status**: Up/Down
- **Response Time**: P50, P95, P99
- **Error Rate**: 4xx, 5xx errors
- **Request Rate**: Requests per second

### Infrastructure Metrics
- **Pod Status**: Running, Pending, Failed
- **Resource Usage**: CPU, Memory, Disk
- **Restart Count**: Pod restarts
- **HPA Status**: Current vs desired replicas

### Business Metrics
- **Availability**: Uptime percentage
- **User Experience**: Response times
- **Cost Impact**: Resource utilization

## 🛠️ Troubleshooting Commands

### Quick Diagnostics
```bash
# Get overall status
kubectl get all -l app.kubernetes.io/name=sre-demo-app

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check service endpoints
kubectl get endpoints sre-demo-app

# Check ingress (if configured)
kubectl get ingress
```

### Detailed Investigation
```bash
# Describe resources
kubectl describe deployment sre-demo-app
kubectl describe service sre-demo-app
kubectl describe pod <pod-name>

# Check logs from multiple pods
kubectl logs -l app.kubernetes.io/name=sre-demo-app --all-containers=true

# Check resource usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app
kubectl top nodes
```

### Network Troubleshooting
```bash
# Test connectivity from within cluster
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup sre-demo-app

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -O- http://sre-demo-app:80
```

## 📝 Post-Incident Review

### Questions to Answer
1. **Detection**: How quickly was the issue detected?
2. **Diagnosis**: How long did it take to identify the root cause?
3. **Resolution**: What was the time to resolution?
4. **Prevention**: What can be done to prevent this in the future?

### Documentation
- **Incident Summary**: Brief description of what happened
- **Timeline**: Detailed timeline of events
- **Root Cause**: Technical explanation of the issue
- **Resolution**: Steps taken to fix the problem
- **Lessons Learned**: Key takeaways and improvements

### Improvements
- **Monitoring**: Add new alerts or dashboards
- **Automation**: Implement automated recovery procedures
- **Documentation**: Update runbooks and procedures
- **Training**: Conduct team training on similar scenarios

---

**Remember**: This is a controlled environment for learning. In production, always follow your organization's incident response procedures and involve the appropriate teams. 