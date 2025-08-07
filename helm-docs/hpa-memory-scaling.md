# HPA Memory Scaling Configuration

## Overview

The Horizontal Pod Autoscaler (HPA) is configured to scale based on memory utilization with the following settings:

## Current Configuration

```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80  # Scale up when memory reaches 80%

resources:
  limits:
    cpu: 1000m
    memory: 2Gi  # Pod will be OOM killed if it exceeds this limit
  requests:
    cpu: 250m
    memory: 256Mi  # Guaranteed memory allocation
```

## How Memory Scaling Works

### Scaling Thresholds
- **Target Memory Utilization**: 80%
- **Memory Limit**: 2Gi (hard limit for OOM kill)
- **Memory Request**: 256Mi (guaranteed allocation)

### Scaling Behavior

#### Scale Up (Add Pods)
- **Trigger**: When average memory usage across all pods > 80% of requests (204.8Mi)
- **Action**: HPA creates new pods to distribute the load
- **Example**: If one pod uses 220Mi (86% of 256Mi request), HPA will scale up

#### Scale Down (Remove Pods)
- **Trigger**: When average memory usage across all pods < 80% of requests (204.8Mi)
- **Action**: HPA removes excess pods
- **Cooldown**: 5 minutes (default HPA behavior)

### Memory Protection

#### Pod Level Protection
- **Memory Limit**: 2Gi (hard limit)
- **OOM Kill**: Pod gets killed if it exceeds 2Gi
- **Your "80% upper limit"**: This is actually the 2Gi limit, not an HPA threshold

#### Application Level Protection
- **Memory Leak Simulation**: Controlled via API calls
- **Safe Demo**: Memory leak stays within 2Gi limit
- **Real Protection**: In production, pods would be killed and restarted if they exceed 2Gi

## Example Scenarios

### Scenario 1: Memory Leak Demo
```
Pod 1: 20MB → 1GB → 1.5GB (within 2Gi limit)
HPA: No scaling (memory < 80% of 256Mi = 204.8Mi)
Result: Single pod handles the load
```

### Scenario 2: High Memory Usage
```
Pod 1: 220Mi (86% of 256Mi request)
HPA: Scales up to 2 pods
Result: Load distributed across 2 pods
```

### Scenario 3: Memory Limit Exceeded
```
Pod 1: 2.1GB (exceeds 2Gi limit)
Kubernetes: OOM kills the pod
HPA: Creates replacement pod
Result: Pod restart cycle until issue resolved
```

## Verification Commands

```bash
# Check HPA status
kubectl get hpa -A

# Check current memory usage
kubectl top pods

# Check HPA events
kubectl describe hpa sre-demo-app

# Check pod resource usage
kubectl describe pod <pod-name>
```

## Demo Integration

### During Demo
- **HPA Disabled**: `minReplicas: 1, maxReplicas: 1` (prevents scaling during demo)
- **Memory Leak**: Controlled simulation within safe limits
- **No Auto-Scaling**: Ensures predictable demo behavior

### After Demo
- **HPA Re-enabled**: `minReplicas: 1, maxReplicas: 5` (normal operation)
- **Memory Scaling**: Active based on 40% threshold
- **Production Ready**: Real memory-based autoscaling

## Benefits of 80% Target

1. **Efficient Resource Usage**: Scales only when memory pressure is significant
2. **Cost Optimization**: Avoids unnecessary pod creation
3. **Load Distribution**: Spreads load across multiple pods when needed
4. **High Availability**: Reduces single point of failure
5. **Balanced Approach**: Good balance between resource efficiency and responsiveness

## Monitoring

### Grafana Dashboards
- Memory usage per pod
- HPA scaling events
- Pod count over time

### Alerts
- Memory usage > 70% (warning)
- Memory usage > 85% (critical)
- HPA scaling failures

## Troubleshooting

### HPA Not Scaling
1. Check if metrics-server is running
2. Verify memory requests are set
3. Check HPA events: `kubectl describe hpa`

### Pods Getting Killed
1. Check memory limits vs usage
2. Investigate memory leaks
3. Consider increasing memory limits

### Scaling Too Aggressively
1. Increase target percentage (e.g., 90%)
2. Add scaling stabilization window
3. Review application memory patterns
