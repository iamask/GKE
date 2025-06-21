# Kubernetes Scaling Guide

This document provides comprehensive information about scaling strategies and implementations for the Express.js application running on Kubernetes.

## Table of Contents

1. [Scaling Concepts](#scaling-concepts)
2. [Manual Scaling](#manual-scaling)
3. [Horizontal Pod Autoscaler (HPA)](#horizontal-pod-autoscaler-hpa)
4. [Vertical Pod Autoscaler (VPA)](#vertical-pod-autoscaler-vpa)
5. [Cluster Autoscaler](#cluster-autoscaler)
6. [Custom Metrics Scaling](#custom-metrics-scaling)
7. [Scheduled Scaling](#scheduled-scaling)
8. [Best Practices](#best-practices)
9. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
10. [Practical Examples](#practical-examples)

---

## Scaling Concepts

### What is Scaling?

Scaling in Kubernetes refers to adjusting the number of resources (pods, nodes) to handle varying workloads efficiently.

### Types of Scaling

1. **Horizontal Scaling**: Adding/removing pods (most common)
2. **Vertical Scaling**: Increasing/decreasing pod resources
3. **Cluster Scaling**: Adding/removing nodes

### Current Application Setup

- **Deployment**: `express-app`
- **Namespace**: `gke-learning`
- **Current Replicas**: 2
- **Resource Limits**: CPU 100m, Memory 128Mi
- **Resource Requests**: CPU 50m, Memory 64Mi

---

## Manual Scaling

### Basic Scaling Commands

```bash
# Scale to specific number of replicas
kubectl scale deployment express-app -n gke-learning --replicas=5

# Scale up by increment
kubectl scale deployment express-app -n gke-learning --replicas=+2

# Scale down by decrement
kubectl scale deployment express-app -n gke-learning --replicas=-1

# Check current scaling status
kubectl get deployment express-app -n gke-learning
```

### Scaling Process

1. **Command Execution**: kubectl sends scaling request to API server
2. **Controller Processing**: ReplicaSet controller processes the request
3. **Pod Management**: Creates or terminates pods to match desired state
4. **Service Update**: Load balancer automatically distributes traffic

### Example Scaling Session

```bash
# Check initial state
kubectl get pods -n gke-learning
# Output:
# express-app-59fb76f75b-bwmfh   1/1     Running   0          18m
# express-app-59fb76f75b-nv848   1/1     Running   0          18m

# Scale up to 4 replicas
kubectl scale deployment express-app -n gke-learning --replicas=4

# Watch scaling in progress
kubectl get pods -n gke-learning -w

# Check final state
kubectl get pods -n gke-learning
# Output:
# express-app-59fb76f75b-bwmfh   1/1     Running   0          18m
# express-app-59fb76f75b-nv848   1/1     Running   0          18m
# express-app-59fb76f75b-xyz123   1/1     Running   0          30s
# express-app-59fb76f75b-abc456   1/1     Running   0          25s
```

---

## Horizontal Pod Autoscaler (HPA)

### Overview

HPA automatically scales the number of pods based on CPU/memory utilization or custom metrics.

### Prerequisites

```bash
# Enable metrics server in Minikube
minikube addons enable metrics-server

# Verify metrics server is running
kubectl get pods -n kube-system | grep metrics-server
```

### HPA Configuration

Create `k8s/hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: express-app-hpa
  namespace: gke-learning
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: express-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

### Apply HPA

```bash
kubectl apply -f k8s/hpa.yaml
```

### HPA Parameters Explained

- **minReplicas**: Minimum number of pods (2)
- **maxReplicas**: Maximum number of pods (10)
- **targetCPUUtilizationPercentage**: Scale when CPU hits 70%
- **targetMemoryUtilizationPercentage**: Scale when memory hits 80%
- **stabilizationWindowSeconds**: Wait time before scaling down (5 minutes)

### Quick HPA Setup

```bash
# Create HPA with kubectl
kubectl autoscale deployment express-app -n gke-learning \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

---

## Vertical Pod Autoscaler (VPA)

### Overview

VPA automatically adjusts pod resource requests and limits based on usage patterns.

### VPA Configuration

Create `k8s/vpa.yaml`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: express-app-vpa
  namespace: gke-learning
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: express-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        minAllowed:
          cpu: 50m
          memory: 64Mi
        maxAllowed:
          cpu: 200m
          memory: 256Mi
        controlledResources: ["cpu", "memory"]
```

### VPA Modes

- **Off**: Only provides recommendations
- **Initial**: Only sets initial resource requests
- **Auto**: Automatically adjusts resources (requires pod restart)

---

## Cluster Autoscaler

### Overview

Cluster Autoscaler automatically adjusts the number of nodes in your cluster.

### Configuration (Cloud Environments)

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: ClusterAutoscaler
metadata:
  name: cluster-autoscaler
spec:
  scaleDown:
    enabled: true
    delayAfterAdd: 10m
    delayAfterDelete: 10s
    delayAfterFailure: 3m
  scaleDownUnneeded: 10m
  maxNodeProvisionTime: 15m
  nodeGroups:
    - minSize: 1
      maxSize: 5
      name: node-group-1
```

---

## Custom Metrics Scaling

### Overview

Scale based on custom metrics like HTTP requests per second, queue length, etc.

### Custom Metrics HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: express-app-custom-hpa
  namespace: gke-learning
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: express-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Object
      object:
        metric:
          name: requests-per-second
        describedObject:
          apiVersion: networking.k8s.io/v1
          kind: Ingress
          name: express-app-ingress
        target:
          type: Value
          value: 100
```

---

## Scheduled Scaling

### CronHPA Configuration

For predictable traffic patterns, use scheduled scaling:

```yaml
apiVersion: autoscaling/v2
kind: CronHorizontalPodAutoscaler
metadata:
  name: express-app-cronhpa
  namespace: gke-learning
spec:
  schedule: "0 9 * * 1-5" # Weekdays at 9 AM
  timezone: "UTC"
  jobTemplate:
    spec:
      template:
        spec:
          scaleTargetRef:
            apiVersion: apps/v1
            kind: Deployment
            name: express-app
          minReplicas: 5
          maxReplicas: 10
```

### Schedule Examples

- `"0 9 * * 1-5"`: Weekdays at 9 AM
- `"0 18 * * 1-5"`: Weekdays at 6 PM
- `"0 0 * * 0"`: Sundays at midnight
- `"*/30 * * * *"`: Every 30 minutes

---

## Best Practices

### 1. Resource Configuration

Ensure proper resource limits and requests:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

### 2. HPA Configuration

```yaml
# Recommended HPA settings
spec:
  minReplicas: 2 # Always have redundancy
  maxReplicas: 10 # Prevent runaway scaling
  targetCPUUtilizationPercentage: 70 # Conservative threshold
  scaleDownDelay: 300 # Prevent thrashing
```

### 3. Health Checks

Ensure proper health checks for scaling decisions:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 4. Scaling Guidelines

- **Start Conservative**: Begin with 2-3 replicas
- **Monitor Performance**: Watch metrics during scaling
- **Set Reasonable Limits**: Prevent excessive scaling
- **Test Scaling**: Validate scaling behavior

---

## Monitoring and Troubleshooting

### Check Scaling Status

```bash
# View HPA status
kubectl get hpa -n gke-learning

# Watch HPA in real-time
kubectl get hpa -n gke-learning -w

# Check pod count
kubectl get pods -n gke-learning

# Monitor resource usage
kubectl top pods -n gke-learning
```

### Troubleshooting Commands

```bash
# Check HPA events
kubectl describe hpa express-app-hpa -n gke-learning

# View deployment events
kubectl describe deployment express-app -n gke-learning

# Check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Verify resource limits
kubectl describe pod <pod-name> -n gke-learning
```

### Common Issues

1. **HPA Not Scaling**: Check metrics server and resource limits
2. **Excessive Scaling**: Adjust thresholds and stabilization windows
3. **Scaling Too Slow**: Reduce stabilization window
4. **Resource Pressure**: Increase resource limits

---

## Practical Examples

### Load Testing Script

Create `scripts/load-test.sh`:

```bash
#!/bin/bash
echo "Starting load test for 5 minutes..."
echo "Target: http://localhost:8080/"
echo "Duration: 300 seconds"

for i in {1..300}; do
  curl -s http://localhost:8080/ > /dev/null &
  if [ $((i % 10)) -eq 0 ]; then
    echo "Request $i completed"
  fi
  sleep 1
done

echo "Load test completed!"
echo "Check scaling status with: kubectl get hpa -n gke-learning"
```

### Scaling Test Workflow

```bash
# 1. Enable metrics server
minikube addons enable metrics-server

# 2. Create HPA
kubectl autoscale deployment express-app -n gke-learning \
  --cpu-percent=70 --min=2 --max=10

# 3. Start monitoring
kubectl get hpa -n gke-learning -w &
kubectl get pods -n gke-learning -w &

# 4. Generate load
./scripts/load-test.sh

# 5. Observe scaling
# Watch the terminal for scaling events

# 6. Clean up
pkill -f "kubectl.*-w"
```

### Performance Monitoring

```bash
# Monitor CPU and memory usage
kubectl top pods -n gke-learning

# Check scaling events
kubectl describe hpa express-app-hpa -n gke-learning

# View pod logs
kubectl logs -f deployment/express-app -n gke-learning
```

---

## Scaling Metrics and KPIs

### Key Metrics to Monitor

1. **CPU Utilization**: Target 70% for scaling
2. **Memory Utilization**: Target 80% for scaling
3. **Response Time**: Should remain consistent during scaling
4. **Error Rate**: Should not increase during scaling
5. **Pod Count**: Should match expected scaling behavior

### Scaling Performance Indicators

- **Scale-up Time**: Time from trigger to new pod ready
- **Scale-down Time**: Time from low usage to pod termination
- **Scaling Frequency**: How often scaling occurs
- **Resource Efficiency**: CPU/memory usage per pod

---

## Conclusion

Kubernetes scaling provides powerful automation for handling varying workloads. By implementing proper scaling strategies, you can ensure your Express.js application maintains optimal performance while efficiently using resources.

### Next Steps

1. Implement HPA for automatic scaling
2. Set up monitoring and alerting
3. Test scaling behavior under load
4. Optimize scaling parameters based on usage patterns
5. Consider implementing custom metrics for application-specific scaling

### Resources

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Kubernetes VPA Documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
