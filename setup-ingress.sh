#!/bin/bash

echo "🚀 Setting up Kubernetes cluster with NGINX Ingress Controller"
echo "================================================================"

# Stop and delete existing cluster
echo "📋 Step 1: Stopping and deleting existing Minikube cluster..."
minikube stop
minikube delete

# Start new cluster with ingress addon
echo "📋 Step 2: Starting new Minikube cluster with NGINX ingress..."
minikube start --addons=ingress

# Wait for ingress controller to be ready
echo "📋 Step 3: Waiting for NGINX ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Use Minikube's Docker daemon
echo "📋 Step 4: Setting up Docker environment..."
eval $(minikube docker-env)

# Build Docker image
echo "📋 Step 5: Building Docker image..."
docker build -t asasikumar/gke-express-hello-world:latest .

# Apply Kubernetes manifests
echo "📋 Step 6: Deploying application to Kubernetes..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for pods to be ready
echo "📋 Step 7: Waiting for application pods to be ready..."
kubectl wait --namespace gke-learning \
  --for=condition=ready pod \
  --selector=app=express-app \
  --timeout=120s

# Get Minikube IP and update hosts file
echo "📋 Step 8: Configuring local DNS..."
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Check if entry already exists in hosts file
if ! grep -q "express-app.local" /etc/hosts; then
    echo "$MINIKUBE_IP express-app.local" | sudo tee -a /etc/hosts
    echo "Added express-app.local to /etc/hosts"
else
    echo "express-app.local already exists in /etc/hosts"
fi

# Show status
echo "📋 Step 9: Checking deployment status..."
echo ""
echo "🎯 Cluster Status:"
kubectl get nodes
echo ""
echo "🎯 Pods Status:"
kubectl get pods -n gke-learning
echo ""
echo "🎯 Services Status:"
kubectl get services -n gke-learning
echo ""
echo "🎯 Ingress Status:"
kubectl get ingress -n gke-learning
echo ""
echo "🎯 Ingress Controller Status:"
kubectl get pods -n ingress-nginx

echo ""
echo "✅ Setup Complete!"
echo "================================================================"
echo "🌐 Access your application:"
echo "   - Via Ingress: http://express-app.local"
echo "   - Via Minikube IP: http://$MINIKUBE_IP"
echo "   - Health Check: http://express-app.local/health"
echo "   - Ready Check: http://express-app.local/ready"
echo ""
echo "🔧 Useful Commands:"
echo "   - View logs: kubectl logs -f -n gke-learning deployment/express-app"
echo "   - Check ingress: kubectl describe ingress express-app-ingress -n gke-learning"
echo "   - Port forward: kubectl port-forward -n gke-learning service/express-app-service 8080:80"
echo ""
echo "🧹 To clean up:"
echo "   - Delete resources: kubectl delete -f k8s/"
echo "   - Stop cluster: minikube stop"
echo "   - Delete cluster: minikube delete" 