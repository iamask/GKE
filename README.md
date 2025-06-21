# Express.js Hello World on Kubernetes (Minikube) with NGINX Ingress

This project demonstrates how to containerize a simple Express.js app and deploy it to a local Kubernetes cluster using Minikube with NGINX Ingress Controller. It is designed for beginners who want to learn Kubernetes concepts hands-on.

**New Architecture:** Internet → NGINX Ingress → Service → Pods

---

## 📋 Initial Setup

### Prerequisites

Before you begin, ensure you have the following installed:

```bash
# Check if you have the required tools
docker --version
kubectl version --client
minikube version
```

**Required Tools:**

- **Docker Desktop**: For building and running containers
- **kubectl**: Kubernetes command-line tool
- **Minikube**: Local Kubernetes cluster
- **Node.js**: For local development (optional)

### Installation Commands

If you need to install any tools:

```bash
# Install Docker Desktop (macOS)
brew install --cask docker

# Install kubectl
brew install kubectl

# Install Minikube
brew install minikube

# Install Node.js (for local development)
brew install node
```

---

## 🚀 Quick Start with NGINX Ingress

### Automated Setup (Recommended)

```bash
# Make setup script executable
chmod +x setup-ingress.sh

# Run the complete setup
./setup-ingress.sh
```

This script will:

1. Stop and delete existing Minikube cluster
2. Start new cluster with NGINX ingress addon
3. Build and deploy your application
4. Configure local DNS
5. Show access URLs

### Manual Setup

If you prefer manual setup, follow these steps:

#### 1. Stop Existing Cluster

```bash
minikube stop
minikube delete
```

#### 2. Start New Cluster with Ingress

```bash
minikube start --addons=ingress
```

#### 3. Wait for Ingress Controller

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

#### 4. Build and Deploy

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build image
docker build -t asasikumar/gke-express-hello-world:latest .

# Deploy application
kubectl apply -f k8s/
```

#### 5. Configure Local DNS

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP express-app.local" | sudo tee -a /etc/hosts
```

---

## 🎮 Start, Stop, and Manage Your Cluster

### Starting the Cluster

```bash
# Start with NGINX ingress (recommended)
minikube start --addons=ingress

# Start with additional addons
minikube start --addons=ingress,dashboard,metrics-server

# Start with specific resources
minikube start --memory=4096 --cpus=2 --addons=ingress
```

### Stopping the Cluster

```bash
# Stop cluster (preserves data)
minikube stop

# Delete cluster completely
minikube delete

# Stop and delete in one command
minikube stop && minikube delete
```

### Checking Cluster Status

```bash
# Check if cluster is running
minikube status

# Get cluster info
minikube cluster-info

# Get Minikube IP
minikube ip
```

### Restarting the Application

```bash
# Restart deployment (after code changes)
kubectl rollout restart deployment express-app -n gke-learning

# Wait for pods to be ready
kubectl wait --namespace gke-learning \
  --for=condition=ready pod \
  --selector=app=express-app \
  --timeout=120s
```

### Rebuilding and Redeploying

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild image
docker build -t asasikumar/gke-express-hello-world:latest .

# Restart deployment
kubectl rollout restart deployment express-app -n gke-learning
```

---

## 🌐 Accessing Your Application

### Method 1: Port Forward (Easiest for Development)

```bash
# Start port forwarding in background
kubectl port-forward -n gke-learning service/express-app-service 8080:80

# Test the application
curl http://localhost:8080/

# Health check
curl http://localhost:8080/health

# Ready check
curl http://localhost:8080/ready
```

**Benefits:**

- ✅ Works immediately
- ✅ No additional configuration needed
- ✅ Perfect for development and testing

### Method 2: NGINX Ingress (Production-like)

```bash
# Start minikube tunnel (in separate terminal)
minikube tunnel

# Access via configured hostname
curl http://express-app.local/

# Health check
curl http://express-app.local/health

# Ready check
curl http://express-app.local/ready
```

**Benefits:**

- ✅ Production-like routing
- ✅ Host-based routing
- ✅ SSL/TLS support (when configured)

### Method 3: Direct Minikube IP

```bash
# Get Minikube IP
minikube ip

# Access directly
curl http://$(minikube ip)/

# With specific host header
curl -H "Host: express-app.local" http://$(minikube ip)/
```

**Benefits:**

- ✅ Direct access without tunnel
- ✅ Good for testing ingress rules

### Method 4: Minikube Service (Legacy)

```bash
# Get service URL
minikube service express-app-service -n gke-learning --url

# Open in browser
minikube service express-app-service -n gke-learning
```

---

## 🔍 Monitoring and Troubleshooting

### Check Application Status

```bash
# Check pods
kubectl get pods -n gke-learning

# Check services
kubectl get services -n gke-learning

# Check ingress
kubectl get ingress -n gke-learning

# Check all resources
kubectl get all -n gke-learning
```

### View Logs

```bash
# Application logs
kubectl logs -f deployment/express-app -n gke-learning

# Specific pod logs
kubectl logs -f <pod-name> -n gke-learning

# Ingress controller logs
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller
```

### Access Kubernetes Dashboard

```bash
# Enable dashboard addon (if not already enabled)
minikube addons enable dashboard

# Open dashboard in browser
minikube dashboard

# Get dashboard URL only (without opening browser)
minikube dashboard --url
```

**Dashboard Features:**

- ✅ **Web UI**: Visual management of your cluster
- ✅ **Resource Monitoring**: View pods, services, deployments
- ✅ **Logs**: Access pod logs through the interface
- ✅ **Resource Management**: Create, edit, delete resources
- ✅ **Namespace Switching**: Manage different namespaces

### Debug Common Issues

```bash
# Check pod details
kubectl describe pod <pod-name> -n gke-learning

# Check service details
kubectl describe service express-app-service -n gke-learning

# Check ingress details
kubectl describe ingress express-app-ingress -n gke-learning

# Check events
kubectl get events -n gke-learning --sort-by='.lastTimestamp'
```

### Test Application Endpoints

```bash
# Test main endpoint
curl http://localhost:8080/

# Test health endpoint
curl http://localhost:8080/health

# Test ready endpoint
curl http://localhost:8080/ready

# Test with verbose output
curl -v http://localhost:8080/
```

---

## 📊 Application Endpoints

Your Express.js application provides the following endpoints:

| Endpoint  | Method | Description                | Response           |
| --------- | ------ | -------------------------- | ------------------ |
| `/`       | GET    | Main application endpoint  | JSON with app info |
| `/health` | GET    | Kubernetes health check    | Health status      |
| `/ready`  | GET    | Kubernetes readiness check | Ready status       |

### Example Responses

**Main Endpoint (`/`):**

```json
{
  "message": "Hello World from Express.js on GKE!",
  "timestamp": "2025-06-21T06:15:54.568Z",
  "pod": "express-app-58c69585b5-2brzc",
  "environment": "production"
}
```

**Health Check (`/health`):**

```json
{
  "status": "healthy",
  "timestamp": "2025-06-21T06:15:57.183Z"
}
```

**Ready Check (`/ready`):**

```json
{
  "status": "ready",
  "timestamp": "2025-06-21T06:16:00.365Z"
}
```

---

## 🔧 Configuration Files

### Project Structure

- `app.js` — Express.js Hello World app
- `Dockerfile` — Containerizes the app (updated for npm install)
- `.dockerignore` — Keeps Docker image clean
- `setup-ingress.sh` — Automated setup script with NGINX ingress
- `k8s/` — Kubernetes manifests:
  - `namespace.yaml` — Namespace for isolation
  - `configmap.yaml` — App configuration
  - `deployment.yaml` — Deploys the app
  - `service.yaml` — Exposes the app (ClusterIP)
  - `ingress.yaml` — NGINX ingress routing rules

### Dockerfile Changes

The Dockerfile was updated to fix build issues:

```dockerfile
# Changed from npm ci to npm install
RUN npm install --only=production
```

**Why this change:**

- `npm ci` requires `package-lock.json` file
- `npm install` works with just `package.json`
- More flexible for development environments

---

## NGINX Ingress Configuration

### Ingress Rules

The `k8s/ingress.yaml` file configures routing:

```yaml
spec:
  ingressClassName: nginx
  rules:
    - host: express-app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: express-app-service
                port:
                  number: 80
```

### Ingress Annotations

- `rewrite-target: /` - Rewrites URL paths
- `ssl-redirect: "false"` - Disables SSL redirect for development
- `rate-limit: "100"` - Limits requests per minute
- `rate-limit-window: "1m"` - Rate limit window

---

## 🧹 Cleanup and Maintenance

### Clean Up Resources

```bash
# Delete all application resources
kubectl delete -f k8s/

# Delete namespace
kubectl delete namespace gke-learning

# Stop cluster
minikube stop

# Delete cluster completely
minikube delete
```

### Remove from Hosts File

```bash
# Remove the DNS entry
sudo sed -i '' '/express-app.local/d' /etc/hosts
```

### Clean Docker Images

```bash
# Remove local image
docker rmi asasikumar/gke-express-hello-world:latest

# Clean up unused images
docker image prune -f
```

---

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Port Forward Not Working

```bash
# Check if port is already in use
lsof -i :8080

# Kill existing process
kill -9 <PID>

# Restart port forward
kubectl port-forward -n gke-learning service/express-app-service 8080:80
```

#### 2. Ingress Not Accessible

```bash
# Check ingress controller status
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress express-app-ingress -n gke-learning

# Start minikube tunnel
minikube tunnel
```

#### 3. Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n gke-learning

# Check pod logs
kubectl logs <pod-name> -n gke-learning

# Check image pull policy
kubectl get deployment express-app -n gke-learning -o yaml
```

#### 4. DNS Resolution Issues

```bash
# Check hosts file
cat /etc/hosts | grep express-app

# Update hosts file
MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP express-app.local" | sudo tee -a /etc/hosts
```

---

## 📚 Additional Resources

### Useful Commands Reference

```bash
# Cluster management
minikube start --addons=ingress
minikube stop
minikube delete
minikube status

# Application management
kubectl apply -f k8s/
kubectl delete -f k8s/
kubectl rollout restart deployment express-app -n gke-learning

# Monitoring
kubectl get all -n gke-learning
kubectl logs -f deployment/express-app -n gke-learning
kubectl describe ingress express-app-ingress -n gke-learning

# Dashboard
minikube addons enable dashboard
minikube dashboard

# Access
kubectl port-forward -n gke-learning service/express-app-service 8080:80
minikube tunnel
curl http://localhost:8080/
```

### Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Express.js Documentation](https://expressjs.com/)

---

## 🎯 Summary

This setup provides:

✅ **Complete Kubernetes environment** with NGINX ingress controller  
✅ **Multiple access methods** for different use cases  
✅ **Production-like architecture** for learning  
✅ **Easy start/stop procedures** for development  
✅ **Comprehensive monitoring** and troubleshooting tools  
✅ **Automated setup script** for quick deployment

The application is now running with a proper ingress controller, providing a solid foundation for learning Kubernetes concepts and developing containerized applications! 🚀
