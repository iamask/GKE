# 🚀 Kubernetes Scaling Guide for Express.js + MongoDB on Minikube

This guide covers various scaling strategies for your Express.js + MongoDB application running on Minikube.

---

## 📊 Current Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          NGINX INGRESS                                      │
│                    (External Traffic Router)                                │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      EXPRESS.JS SERVICE                                     │
│                    (Load Balancer)                                          │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ EXPRESS.JS  │ │ EXPRESS.JS  │ │ EXPRESS.JS  │
│   POD 1     │ │   POD 2     │ │   POD 3     │
│ (Port 3000) │ │ (Port 3000) │ │ (Port 3000) │
└─────────────┘ └─────────────┘ └─────────────┘
```

- **Ingress:** Handles external traffic and load balancing
- **Service:** Internal routing to Express.js pods
- **Pods:** Run Express.js app (currently 2 replicas)
- **MongoDB:** Single StatefulSet instance
- **Namespace:** All resources isolated in `express-mongo-app`

---

## 🔧 Manual Scaling

### Scale Express.js Deployment

```bash
# Scale to 5 replicas
kubectl scale deployment express-app -n express-mongo-app --replicas=5

# Scale up by 2
kubectl scale deployment express-app -n express-mongo-app --replicas=+2

# Scale down by 1
kubectl scale deployment express-app -n express-mongo-app --replicas=-1

# Check current deployment status
kubectl get deployment express-app -n express-mongo-app
```

### Monitor Scaling Progress

```bash
# Watch pods being created/destroyed
kubectl get pods -n express-mongo-app -w

# Scale down to 4 replicas
kubectl scale deployment express-app -n express-mongo-app --replicas=4

# Watch the scaling process
kubectl get pods -n express-mongo-app -w

# Check final status
kubectl get pods -n express-mongo-app
```

---

## 🤖 Horizontal Pod Autoscaler (HPA)

### Create HPA for Express.js

```yaml
# hpa-express-app.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: express-app-hpa
  namespace: express-mongo-app
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
# Create HPA
kubectl autoscale deployment express-app -n express-mongo-app \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# Or apply the YAML file
kubectl apply -f hpa-express-app.yaml
```

### Monitor HPA

```bash
# Check HPA status
kubectl get hpa -n express-mongo-app

# Watch HPA in real-time
kubectl get hpa -n express-mongo-app -w

# Check current pods
kubectl get pods -n express-mongo-app

# Monitor resource usage
kubectl top pods -n express-mongo-app
```

### Troubleshoot HPA

```bash
# Describe HPA for detailed information
kubectl describe hpa express-app-hpa -n express-mongo-app

# Check deployment status
kubectl describe deployment express-app -n express-mongo-app

# Check specific pod
kubectl describe pod <pod-name> -n express-mongo-app
```

---

## 📈 Load Testing

### Generate Load for Testing

```bash
# Simple load test with curl
for i in {1..100}; do
  curl -s http://localhost:8080/ > /dev/null &
done

# More sophisticated load test with Apache Bench
ab -n 1000 -c 10 http://localhost:8080/

# Load test with hey (if installed)
hey -n 1000 -c 10 http://localhost:8080/
```

### Monitor During Load Test

```bash
# Watch HPA scaling
kubectl get hpa -n express-mongo-app -w &
kubectl get pods -n express-mongo-app -w &

# Monitor resource usage
kubectl top pods -n express-mongo-app

# Check HPA details
kubectl describe hpa express-app-hpa -n express-mongo-app
```

---

## 🎯 Scaling Best Practices

### 1. Resource Limits and Requests

Ensure your pods have proper resource limits:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

### 2. Health Checks

Implement proper health checks:

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

### 3. Graceful Shutdown

Ensure your application handles SIGTERM properly:

```javascript
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully");
  server.close(() => {
    console.log("Process terminated");
  });
});
```

### 4. Database Scaling

Consider MongoDB scaling strategies:

- **Read Replicas:** Add MongoDB secondary nodes
- **Sharding:** Distribute data across multiple clusters
- **Connection Pooling:** Optimize database connections

---

## 🔍 Monitoring and Alerts

### Metrics to Monitor

```bash
# Pod metrics
kubectl top pods -n express-mongo-app

# Node metrics
kubectl top nodes

# HPA metrics
kubectl get hpa -n express-mongo-app

# Resource usage
kubectl describe pod <pod-name> -n express-mongo-app
```

### Dashboard Monitoring

```bash
# Open Kubernetes Dashboard
minikube dashboard

# Navigate to:
# 1. Namespace: express-mongo-app
# 2. Deployments → express-app
# 3. Check Metrics tab for CPU/Memory usage
```

---

## 🧹 Cleanup

### Remove HPA

```bash
# Delete HPA
kubectl delete hpa express-app-hpa -n express-mongo-app

# Or delete all resources
kubectl delete -f k8s/
```

### Scale Down

```bash
# Scale back to original replicas
kubectl scale deployment express-app -n express-mongo-app --replicas=2
```

---

## 📚 Additional Resources

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Kubernetes Scaling Best Practices](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment)
- [MongoDB Scaling Strategies](https://docs.mongodb.com/manual/core/sharding/)
- [Express.js Performance](https://expressjs.com/en/advanced/best-practices-performance.html)
