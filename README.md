# 🚀 Express.js + MongoDB on Kubernetes (Minikube)

A production-ready, cluster-agnostic template for running an Express.js app with MongoDB on Kubernetes, using NGINX Ingress and Minikube for local development.

---

## 📐 Architecture

```text
Internet → NGINX Ingress → Express.js Service → Express.js Pods
                                    ↓
                              ┌─────────┬─────────┐
                              ↓         ↓         ↓
                        Express-1   Express-2   Express-3
                        (Pod 1)     (Pod 2)     (Pod 3)
```

- **Ingress:** Handles external traffic, SSL, and load balancing
- **Service (ClusterIP):** Internal routing to pods
- **Pods:** Run Express.js app (2+ replicas)
- **MongoDB:** StatefulSet with persistent storage, accessed via headless service
- **Namespace:** All resources isolated in `gke-learning`

---

## 📁 Directory Structure

```
├── 📄 app.js                          # Express.js application with MongoDB integration
├── 📄 Dockerfile                      # Multi-stage Docker build for production
├── 📄 package.json                    # Node.js dependencies and scripts
├── 📄 package-lock.json               # Locked dependency versions
├── 📄 deploy-app.sh                   # Deployment script for Minikube
├── 📄 README.md                       # This documentation file
├── 📄 .dockerignore                   # Files to exclude from Docker build
├── 📄 .gitignore                      # Git ignore patterns
│
└── 📁 k8s/                            # Kubernetes manifests
    ├──  gke-namespace.yaml          # Namespace definition (gke-learning)
    │
    ├──  express-deployment.yaml     # Express.js app deployment (replicas, health checks)
    ├── 📄 express-service.yaml        # ClusterIP service for Express.js
    ├── 📄 express-ingress.yaml        # NGINX ingress rules and routing
    ├── 📄 express-configmap.yaml      # App configuration (env vars)
    │
    ├── 📄 mongo-statefulset.yaml      # MongoDB StatefulSet (persistent storage)
    ├──  mongo-service.yaml          # Headless service for MongoDB
    ├── 📄 mongo-configmap.yaml        # MongoDB configuration
    └── 📄 mongo-secret.yaml           # MongoDB credentials (base64 encoded)
```

### File Descriptions

#### **Application Files**

- **`app.js`** - Main Express.js application with MongoDB connection, health checks, and API endpoints (`/`, `/mongo`, `/mongo-validate`, `/health`, `/ready`)
- **`Dockerfile`** - Multi-stage build for optimized production image with Node.js 18 Alpine
- **`package.json`** - Node.js dependencies (Express.js, MongoDB driver) and npm scripts
- **`deploy-app.sh`** - Automated deployment script for Minikube (builds image and restarts deployment)

#### **Kubernetes Manifests (`k8s/`)**

**Express.js Application:**

- **`express-deployment.yaml`** - Defines Express.js pods, container image, resource limits, health checks, and environment variables
- **`express-service.yaml`** - Internal ClusterIP service for load balancing between Express.js pods
- **`express-ingress.yaml`** - NGINX ingress configuration for external access and routing
- **`express-configmap.yaml`** - Non-sensitive configuration (environment variables, app settings)

**MongoDB Database:**

- **`mongo-statefulset.yaml`** - MongoDB StatefulSet with persistent storage, stable identities, and resource limits
- **`mongo-service.yaml`** - Headless service providing stable DNS names for MongoDB pods
- **`mongo-configmap.yaml`** - MongoDB configuration (ports, hostnames, replica set settings)
- **`mongo-secret.yaml`** - Sensitive data (usernames, passwords) stored in base64 format

**Shared Resources:**

- **`gke-namespace.yaml`** - Namespace definition for resource isolation and organization

### Scalable Naming Convention

The manifest files follow a clear naming pattern for easy extension:

- **Service-specific**: `{service}-deployment.yaml`, `{service}-service.yaml`, etc.
- **Easy to add**: `redis-deployment.yaml`, `postgres-service.yaml`, `nginx-configmap.yaml`

---

## 🔄 Request Flow

1. **User** sends request via port-forwarding or ingress
2. **NGINX Ingress** routes to `express-service`
3. **Service** load-balances to Express.js pods
4. **Pod** connects to MongoDB via `mongo-service`
5. **MongoDB StatefulSet** provides persistent storage

---

## 🚀 Quick Start (Minikube)

### Prerequisites

- Docker & Minikube
- kubectl
- Docker Hub account (for cloud, not needed for local Minikube)

### 1. Start Minikube with Required Addons

```bash
minikube start --addons=ingress,metrics-server
```

**Why metrics-server?** Enables CPU and memory monitoring in the Kubernetes Dashboard and via `kubectl top` commands.

### 2. Point Docker to Minikube

```bash
eval $(minikube docker-env)
```

### 3. Build the Docker Image

```bash
docker build -t asasikumar/gke-express-hello-world:latest .
```

### 4. Deploy All Resources

```bash
kubectl apply -f k8s/
```

### 5. Wait for Everything to Be Ready

```bash
kubectl wait --for=condition=ready pod -l app=mongo -n gke-learning --timeout=300s
kubectl wait --for=condition=ready pod -l app=express-app -n gke-learning --timeout=300s
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s
```

### 6. (Optional) Add Demo Data to MongoDB

```bash
kubectl exec -n gke-learning mongo-0 -- mongosh --username root --password password --authenticationDatabase admin --eval "use express_app; db.messages.insertOne({message: 'Hello World from Express.js and Mongo', timestamp: new Date(), source: 'manual_entry'})"
```

### 7. Port-Forward and Test

```bash
kubectl port-forward -n gke-learning service/express-app-service 8080:80 &
curl http://localhost:8080/mongo-validate
```

### 8. View Resource Metrics

```bash
# View pod resource usage
kubectl top pods -n gke-learning

# View node resource usage
kubectl top nodes

# Access the dashboard for visual monitoring
minikube dashboard --url &
```

---

## 🚀 Automated Deployment (Recommended)

For the easiest deployment experience, use the automated script:

```bash
./deploy-app.sh
```

This script automatically:

- ✅ Ensures Minikube is running with required addons (ingress + metrics-server)
- ✅ Builds and deploys your application
- ✅ Waits for all components to be ready
- ✅ Generates initial load to create metrics
- ✅ Shows current resource usage
- ✅ Offers interactive port-forwarding

---

## 🗄️ MongoDB Configuration & Admin Access

### Secrets

```yaml
# k8s/mongo-secret.yaml
data:
  mongo-root-username: cm9vdA== # "root"
  mongo-root-password: cGFzc3dvcmQ= # "password"
  mongo-database: ZXhwcmVzc19hcHA= # "express_app"
```

### How Express.js Connects

- Uses env vars from ConfigMap and Secret
- Connection string:  
  `mongodb://root:password@mongo-service:27017/express_app?authSource=admin`

### Admin Access

- **CLI:**  
  `kubectl exec -it mongo-0 -n gke-learning -- mongosh --username root --password password --authenticationDatabase admin`
- **Port Forward:**  
  `kubectl port-forward -n gke-learning service/mongo-service 27017:27017 &`  
  Then connect with Compass or mongosh.

---

## 🔄 How to Apply Code or Database Changes (Minikube)

1. **Point Docker to Minikube:**  
   `eval $(minikube docker-env)`
2. **Rebuild the image:**  
   `docker build -t asasikumar/gke-express-hello-world:latest .`
3. **Set `imagePullPolicy: Never` in deployment**
4. **Restart deployment:**  
   `kubectl rollout restart deployment/express-app -n gke-learning`
5. **Wait for pods:**  
   `kubectl wait --for=condition=ready pod -l app=express-app -n gke-learning --timeout=300s`
6. **(Optional) Add MongoDB data:**  
   `kubectl exec -n gke-learning mongo-0 -- mongosh --username root --password password --authenticationDatabase admin --eval "use express_app; db.messages.insertOne({message: 'Hello World from Express.js and Mongo', timestamp: new Date(), source: 'manual_entry'})"`

---

## 🎯 Common Commands

```bash
# Get all resources
kubectl get all -n gke-learning

# View logs
kubectl logs -f deployment/express-app -n gke-learning
kubectl logs -f statefulset/mongo -n gke-learning

# Port forward
kubectl port-forward -n gke-learning service/express-app-service 8080:80

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/mongo
curl http://localhost:8080/mongo-validate

# 📊 Monitoring & Metrics
kubectl top pods -n gke-learning          # View pod CPU/memory usage
kubectl top nodes                         # View node resource usage
kubectl get events -n gke-learning        # View recent events
kubectl describe pod <pod-name> -n gke-learning  # Detailed pod info

# 🔧 Metrics Server Management
kubectl get pods -n kube-system | grep metrics-server  # Check metrics server status
minikube addons enable metrics-server     # Enable metrics server
kubectl logs -n kube-system deployment/metrics-server  # View metrics server logs
```

---

## �� Minikube Dashboard & Monitoring

Access the Kubernetes Dashboard to monitor your application through a web-based UI:

```bash
minikube dashboard --url &
```

### What You Can Do in the Dashboard:

- **📈 View Resource Metrics**: Real-time CPU and memory usage for all pods
- **📊 Monitor Performance**: Track resource consumption trends over time
- **🔍 View Pod Status**: See real-time status of Express.js and MongoDB pods
- **📋 View Logs**: Access application logs directly from the UI
- **⚙️ Manage Deployments**: Scale, restart, or update deployments
- **🌐 Service Discovery**: View services, endpoints, and networking
- **📁 Namespace Management**: Navigate between different namespaces
- **📢 Event Monitoring**: Track Kubernetes events and issues

### Dashboard Features:

- **📈 Real-time Metrics**: Live CPU and memory updates every 60 seconds
- **📊 Resource Visualization**: Charts and graphs for resource consumption
- **📝 Log Streaming**: Real-time log viewing for troubleshooting
- **✏️ YAML Editor**: Direct manifest editing capabilities
- **🌍 Multi-namespace Support**: Switch between namespaces easily
- **📱 Responsive Design**: Works on desktop and mobile devices

### Metrics Dashboard Navigation:

1. **Navigate to namespace**: `gke-learning`
2. **View Deployments**: Click on `express-app` deployment
3. **Check Metrics Tab**: See CPU/memory usage charts
4. **Monitor Individual Pods**: Click on specific pods for detailed metrics
5. **View Node Metrics**: Go to Nodes section for cluster-wide metrics

### Troubleshooting Metrics:

If metrics aren't showing in the dashboard:

```bash
# Check if metrics server is running
kubectl get pods -n kube-system | grep metrics-server

# Enable metrics server if disabled
minikube addons enable metrics-server

# Wait for metrics to be available
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

# Generate some load to create metrics
for i in {1..5}; do curl -s http://localhost:8080/ > /dev/null; done
```

---

## 📚 Endpoints

| Endpoint          | Method | Description                           |
| ----------------- | ------ | ------------------------------------- |
| `/`               | GET    | App health/info (not from MongoDB)    |
| `/mongo`          | GET    | Fetches a message from MongoDB        |
| `/mongo-validate` | GET    | Validates specific entry from MongoDB |
| `/health`         | GET    | Kubernetes health check               |
| `/ready`          | GET    | Kubernetes readiness check            |

---

## 📝 Notes

- Use `/mongo` or `/mongo-validate` to confirm data is coming from MongoDB.
- Always build images inside Minikube for local development.
- Use `imagePullPolicy: Never` for local images.
- Namespace isolation keeps resources organized.
- MongoDB uses StatefulSet for persistent storage.
- **📊 Metrics server** provides real-time CPU and memory monitoring.
- **📈 Dashboard metrics** update every 60 seconds by default.
- **🔧 Use `./deploy-app.sh`** for automated deployment with metrics setup.
- **📋 Monitor resource usage** to prevent pod evictions and OOM issues.

---

## 🛠️ Helpful Links

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Express.js Documentation](https://expressjs.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)

---

## 🏗️ Architecture Diagrams & Future Improvements

### **Current Architecture (Single MongoDB + Metrics)**

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
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
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      MONGODB SERVICE                                        │
│                    (Headless Service)                                       │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MONGODB STATEFULSET                                      │
│                ┌─────────────────────────┐                                  │
│                │     MONGODB POD         │                                  │
│                │   (Port 27017)          │                                  │
│                │   Persistent Storage    │                                  │
│                └─────────────────────────┘                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                    MONITORING & METRICS                                     │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                KUBERNETES DASHBOARD                                  │   │
│  │              (Web-based UI)                                         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ▲                                              │
│                              │                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                  METRICS SERVER                                      │   │
│  │              (CPU/Memory Metrics)                                    │   │
│  │              Updates every 60s                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Current Benefits:**

- ✅ **Simple setup** with minimal complexity
- ✅ **Persistent storage** via StatefulSet
- ✅ **Load balancing** for Express.js pods
- ✅ **Health checks** and monitoring
- ✅ **📊 Real-time metrics** via metrics server
- ✅ **📈 Dashboard monitoring** with CPU/memory visualization
- ✅ **🔧 Automated deployment** with metrics setup

**Current Limitations:**

- ❌ **Single point of failure** (MongoDB)
- ❌ **No read scaling** (single MongoDB instance)
- ❌ **Manual failover** required
- ❌ **Limited performance** under high load

---

### **Future Architecture 1: MongoDB Replica Set**

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
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
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  MONGODB REPLICA SET SERVICE                                │
│                    (Load Balancer)                                          │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ MONGODB     │ │ MONGODB     │ │ MONGODB     │
│ PRIMARY     │ │ SECONDARY   │ │ SECONDARY   │
│ (mongo-0)   │ │ (mongo-1)   │ │ (mongo-2)   │
│ Writes      │ │ Reads       │ │ Reads       │
│ Replication │ │ Replication │ │ Replication │
└─────────────┘ └─────────────┘ └─────────────┘
```

**MongoDB Replica Set Benefits:**

- ✅ **High availability** with automatic failover
- ✅ **Read scaling** across multiple nodes
- ✅ **Data redundancy** (3 copies)
- ✅ **Automatic recovery** from node failures
- ✅ **Write consistency** through primary node

---

### **Future Architecture 2: Redis Caching Layer**

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
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
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   REDIS     │ │   REDIS     │ │   REDIS     │
│   POD 1     │ │   POD 2     │ │   POD 3     │
│ (Port 6379) │ │ (Port 6379) │ │ (Port 6379) │
│   Cache     │ │   Cache     │ │   Cache     │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      MONGODB SERVICE                                        │
│                    (Single Instance)                                        │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MONGODB STATEFULSET                                      │
│                ┌─────────────────────────┐                                  │
│                │     MONGODB POD         │                                  │
│                │   (Port 27017)          │                                  │
│                │   Persistent Storage    │                                  │
│                └─────────────────────────┘                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Redis Caching Benefits:**

- ✅ **Faster read performance** (in-memory cache)
- ✅ **Reduced MongoDB load** (cached queries)
- ✅ **Session storage** for user sessions
- ✅ **Rate limiting** and throttling
- ✅ **Simple setup** compared to replica set

---

### **Future Architecture 3: Hybrid (MongoDB + Redis)**

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
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
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   REDIS     │ │   REDIS     │ │   REDIS     │
│   POD 1     │ │   POD 2     │ │   POD 3     │
│ (Port 6379) │ │ (Port 6379) │ │ (Port 6379) │
│   Cache     │ │   Cache     │ │   Cache     │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  MONGODB REPLICA SET SERVICE                                │
│                    (Load Balancer)                                          │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ MONGODB     │ │ MONGODB     │ │ MONGODB     │
│ PRIMARY     │ │ SECONDARY   │ │ SECONDARY   │
│ (mongo-0)   │ │ (mongo-1)   │ │ (mongo-2)   │
│ Writes      │ │ Reads       │ │ Reads       │
│ Replication │ │ Replication │ │ Replication │
└─────────────┘ └─────────────┘ └─────────────┘
```

**Hybrid Architecture Benefits:**

- ✅ **Maximum performance** (Redis + MongoDB replica set)
- ✅ **High availability** (automatic failover)
- ✅ **Read scaling** (Redis cache + MongoDB secondaries)
- ✅ **Write consistency** (MongoDB primary)
- ✅ **Session management** (Redis)
- ✅ **Data durability** (MongoDB replication)

---

## 🚀 **Future Improvements Roadmap**

### **Phase 1: Immediate (Current)**

- ✅ **Single MongoDB** with persistent storage
- ✅ **Express.js** load balancing
- ✅ **Basic monitoring** and health checks
- ✅ **NGINX Ingress** for external access

### **Phase 2: High Availability (Next)**

- 🔄 **MongoDB Replica Set** (3 nodes)
- 🔄 **Automatic failover** and recovery
- 🔄 **Read scaling** across secondary nodes
- 🔄 **Enhanced monitoring** and alerting

### **Phase 3: Performance Optimization**

- 🔄 **Redis caching layer** for hot data
- 🔄 **Session management** via Redis
- 🔄 **Query optimization** and indexing
- 🔄 **Connection pooling** optimization

### **Phase 4: Production Ready**

- 🔄 **MongoDB Atlas** migration (cloud-managed)
- 🔄 **Global distribution** and CDN
- 🔄 **Advanced monitoring** (Prometheus + Grafana)
- 🔄 **Automated backups** and disaster recovery

### **Phase 5: Enterprise Features**

- 🔄 **Multi-region deployment**
- 🔄 **Advanced security** (RBAC, encryption)
- 🔄 **API rate limiting** and throttling
- 🔄 **A/B testing** infrastructure

---

## 📊 **Architecture Comparison Matrix**

| Feature               | Current    | Replica Set | Redis Cache | Hybrid     | MongoDB Atlas |
| --------------------- | ---------- | ----------- | ----------- | ---------- | ------------- |
| **Setup Complexity**  | ⭐         | ⭐⭐        | ⭐⭐        | ⭐⭐⭐     | ⭐            |
| **Performance**       | ⭐⭐       | ⭐⭐⭐      | ⭐⭐⭐⭐    | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐    |
| **High Availability** | ⭐         | ⭐⭐⭐⭐    | ⭐⭐        | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐    |
| **Cost**              | ⭐⭐⭐⭐⭐ | ⭐⭐⭐      | ⭐⭐⭐⭐    | ⭐⭐       | ⭐            |
| **Maintenance**       | ⭐⭐⭐⭐   | ⭐⭐        | ⭐⭐⭐      | ⭐         | ⭐⭐⭐⭐⭐    |
| **Scalability**       | ⭐⭐       | ⭐⭐⭐      | ⭐⭐⭐⭐    | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐    |

**Recommendation:** Start with **MongoDB Replica Set** for high availability, then add **Redis** for performance optimization, or migrate to **MongoDB Atlas** for zero operational overhead.
