# 🚨 SRE Incident Detection & Resolution Walkthrough

## 📋 **Overview**

This document provides a complete walkthrough of an incident scenario in our SRE demo environment, covering **detection**, **diagnosis**, and **resolution** using real tools and metrics.

## 🏗️ **Infrastructure Setup (Extra Points ✅)**

### **Infrastructure as Code (Terraform)**
- ✅ **EKS Cluster**: `sre-incident-demo-cluster` in `eu-central-1`
- ✅ **VPC & Networking**: Private/public subnets, NAT Gateway
- ✅ **Node Groups**: Auto-scaling worker nodes
- ✅ **IAM Roles**: Proper permissions for EKS and EBS CSI Driver
- ✅ **Security Groups**: Network security for cluster communication

### **CI/CD Pipeline (GitHub Actions)**
- ✅ **Declarative YAML**: `.github/workflows/deploy.yml`
- ✅ **Automated Testing**: Node.js application tests
- ✅ **Container Build**: Docker image creation and ECR push
- ✅ **Helm Deployment**: Kubernetes deployment with Helm charts
- ✅ **Manual Triggers**: Controlled deployment process

## 🎯 **Sample Application**

### **Application Features**
- **Node.js Express Server**: RESTful API with health checks
- **Built-in Failure Modes**: Simulated incidents for testing
- **Metrics Endpoints**: Prometheus-compatible metrics
- **Auto-scaling**: HPA configured for CPU/memory scaling

### **API Endpoints**
```bash
GET  /                    # Application info
GET  /health             # Health check
GET  /api/data           # External API simulation
GET  /api/stress         # CPU stress test
POST /api/failure-mode   # Set failure simulation
POST /api/memory-leak    # Enable/disable memory leak
POST /api/cpu-stress     # Enable/disable CPU stress
```

## 🚨 **Incident Scenario: Memory Leak Crisis**

### **Scenario Description**
Our application is experiencing a **memory leak** that gradually consumes all available memory, causing:
- Pod restarts
- Increased response times
- Potential service outages
- Resource exhaustion

---

## 🔍 **Phase 1: Incident Detection**

### **1.1 Monitoring Dashboard Alert**

**Tool**: Grafana Dashboard (`http://localhost:3000`)
- **Username**: `admin`
- **Password**: `admin123`

**Detection Method**:
1. **Memory Usage Spike**: Grafana shows memory usage trending upward
2. **Pod Restart Count**: Increasing pod restarts in Kubernetes dashboard
3. **Response Time Degradation**: API response times increasing

**Alert Thresholds**:
```yaml
# Prometheus Alert Rules
- alert: HighMemoryUsage
  expr: container_memory_usage_bytes > 80%
  for: 5m

- alert: PodRestarting
  expr: increase(kube_pod_container_status_restarts_total[5m]) > 0
```

### **1.2 Kubernetes Events**

**Command**: `kubectl get events --sort-by='.lastTimestamp'`

**Detection Signs**:
```bash
# Example output showing memory pressure
LAST SEEN   TYPE      REASON              OBJECT                    MESSAGE
2m          Warning   FailedScheduling     pod/sre-demo-app-xyz     Insufficient memory
1m          Normal    Killing              pod/sre-demo-app-abc     Container memory limit exceeded
```

### **1.3 Application Health Checks**

**Command**: `curl http://<service-url>/health`

**Detection Signs**:
```json
{
  "status": "unhealthy",
  "memory_usage": "95%",
  "uptime": "2h 15m",
  "restarts": 3
}
```

---

## 🔬 **Phase 2: Incident Diagnosis**

### **2.1 Resource Investigation**

**Tool**: Kubernetes Metrics Server
```bash
# Check current resource usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app

# Example output showing memory leak
NAME                           CPU(cores)   MEMORY(bytes)   
sre-demo-app-678c44fb5-n5fs7   1m           512Mi           # Memory growing!
```

### **2.2 Pod Status Analysis**

**Command**: `kubectl describe pod <pod-name>`

**Diagnosis Signs**:
```yaml
# Pod events showing memory pressure
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Warning  OOMKilled  2m    kubelet            Container killed due to memory limit
  Normal   Pulled     1m    kubelet            Container image pulled
  Normal   Created    1m    kubelet            Container created
  Normal   Started    1m    kubelet            Container started
```

### **2.3 Application Logs Analysis**

**Command**: `kubectl logs -l app.kubernetes.io/name=sre-demo-app --tail=50`

**Diagnosis Signs**:
```bash
# Logs showing memory leak
2025-08-05T21:23:12.304Z - Memory leak enabled
2025-08-05T21:24:15.123Z - Memory usage: 256MB
2025-08-05T21:25:20.456Z - Memory usage: 384MB
2025-08-05T21:26:30.789Z - Memory usage: 512MB
```

### **2.4 Grafana Metrics Analysis**

**Dashboard**: SRE Demo Dashboard

**Key Metrics to Investigate**:
1. **Memory Usage Trend**: Steady upward trend
2. **Pod Restart Rate**: Increasing frequency
3. **Response Time**: Degrading over time
4. **Error Rate**: May increase due to OOM kills

---

## 🛠️ **Phase 3: Incident Resolution**

### **3.1 Immediate Response**

**Step 1: Scale Up Resources**
```bash
# Increase memory limits temporarily
kubectl patch deployment sre-demo-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"sre-demo-app","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

**Step 2: Restart Affected Pods**
```bash
# Restart deployment to clear memory
kubectl rollout restart deployment sre-demo-app
```

**Step 3: Scale Out for Redundancy**
```bash
# Increase replicas for better availability
kubectl scale deployment sre-demo-app --replicas=3
```

### **3.2 Root Cause Analysis**

**Investigation Commands**:
```bash
# Check if memory leak simulation is active
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "none"}'

# Check application configuration
kubectl get configmap sre-demo-app -o yaml

# Analyze resource requests/limits
kubectl get deployment sre-demo-app -o yaml | grep -A 10 resources
```

### **3.3 Long-term Fixes**

**Fix 1: Disable Memory Leak Simulation**
```bash
# Use incident simulator to reset
./scripts/incident-simulator.sh
# Select option 6: Reset all simulations
```

**Fix 2: Optimize Resource Limits**
```yaml
# Update Helm values
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"    # Increased from 256Mi
    cpu: "500m"
```

**Fix 3: Add Memory Monitoring**
```yaml
# Add memory alerts to Prometheus
- alert: MemoryLeakDetected
  expr: rate(container_memory_usage_bytes[5m]) > 0
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Memory leak detected in {{ $labels.pod }}"
```

---

## ✅ **Phase 4: Verification & Recovery**

### **4.1 Health Check Verification**

**Commands**:
```bash
# Verify application health
curl http://<service-url>/health

# Check pod status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Verify resource usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app
```

**Expected Results**:
```json
{
  "status": "healthy",
  "memory_usage": "15%",
  "uptime": "5m",
  "restarts": 0
}
```

### **4.2 Metrics Verification**

**Grafana Dashboard Checks**:
- ✅ **Memory Usage**: Stable and within normal range
- ✅ **Pod Restarts**: Zero or minimal
- ✅ **Response Times**: Back to normal baseline
- ✅ **Error Rates**: Minimal or zero

### **4.3 Load Testing**

**Test Commands**:
```bash
# Simulate normal load
for i in {1..10}; do
  curl http://<service-url>/api/data
  sleep 1
done

# Monitor during load test
kubectl top pods -l app.kubernetes.io/name=sre-demo-app --watch
```

---

## 📊 **Phase 5: Post-Incident Review**

### **5.1 Incident Timeline**

**Documentation**:
```markdown
## Incident Summary
- **Start Time**: 2025-08-05 21:23:12 UTC
- **Detection Time**: 2025-08-05 21:25:00 UTC (2m delay)
- **Resolution Time**: 2025-08-05 21:30:00 UTC (7m total)
- **Root Cause**: Memory leak simulation enabled
- **Impact**: 2 pod restarts, 5 minutes of degraded performance
```

### **5.2 Lessons Learned**

**Improvements Identified**:
1. **Faster Detection**: Add memory usage alerts
2. **Better Monitoring**: Implement memory leak detection
3. **Automated Response**: Auto-restart pods on memory pressure
4. **Resource Optimization**: Review and adjust memory limits

### **5.3 Action Items**

**Immediate Actions**:
- [ ] Configure memory usage alerts in Prometheus
- [ ] Add memory leak detection to application
- [ ] Review resource limits for all deployments
- [ ] Document incident response procedures

**Long-term Actions**:
- [ ] Implement automated incident response
- [ ] Add memory profiling to application
- [ ] Create runbooks for common incidents
- [ ] Schedule regular incident response drills

---

## 🎯 **Extra Points Summary**

### **Infrastructure as Code (Terraform) ✅**
- Complete EKS cluster provisioning
- VPC, networking, and security groups
- IAM roles and policies
- Auto-scaling node groups

### **Declarative CI/CD Pipeline (GitHub Actions) ✅**
- YAML-based workflow definitions
- Automated testing and building
- Helm-based deployments
- Manual trigger controls

### **Comprehensive Monitoring ✅**
- Prometheus metrics collection
- Grafana dashboards
- Kubernetes events monitoring
- Application health checks

### **Incident Response Tools ✅**
- Incident simulator script
- Real-time metrics monitoring
- Automated scaling capabilities
- Health check endpoints

---

## 🚀 **How to Run This Demo**

### **1. Deploy Infrastructure**
```bash
./scripts/deploy.sh
```

### **2. Access Monitoring**
```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# URL: http://localhost:3000 (admin/<GRAFANA_PASSWORD>)

# Kubernetes Dashboard
kubectl proxy
# URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### **3. Simulate Incidents**
```bash
./scripts/incident-simulator.sh
```

### **4. Monitor and Respond**
- Watch Grafana dashboards
- Use kubectl commands for investigation
- Apply fixes and verify recovery

---

## 📚 **Additional Resources**

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Prometheus Alerting**: https://prometheus.io/docs/alerting/
- **Grafana Dashboards**: https://grafana.com/docs/
- **SRE Best Practices**: https://sre.google/

---

*This walkthrough demonstrates a complete SRE incident response process using real tools and infrastructure, providing hands-on experience with modern DevOps practices.* 