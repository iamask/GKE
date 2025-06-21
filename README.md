# 🚀 Express.js + MongoDB on Kubernetes (Minikube)

A production-ready, cluster-agnostic template for running an Express.js app with MongoDB on Kubernetes, using NGINX Ingress and Minikube for local development.

---

## 📐 Architecture

```text
Internet → NGINX Ingress → ClusterIP Service → Express.js Pods
                                    ↓
                              MongoDB StatefulSet
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

### 1. Start Minikube

```bash
minikube start --addons=ingress
```

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

---

## 🛠️ Helpful Links

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Express.js Documentation](https://expressjs.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
