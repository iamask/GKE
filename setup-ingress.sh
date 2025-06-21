#!/bin/bash

# This script sets up NGINX Ingress Controller and deploys the Express.js + MongoDB application
# on Minikube with proper ingress configuration for external access.

set -e  # Exit immediately if any command fails

echo "🚀 Setting up NGINX Ingress Controller on Minikube..."

# Check if Minikube is running
if ! minikube status | grep -q "Running"; then
    echo "❌ Minikube is not running. Please start Minikube first:"
    echo "   minikube start --addons=ingress"
    exit 1
fi

# Enable NGINX Ingress addon if not already enabled
if ! minikube addons list | grep -q "ingress.*enabled"; then
    echo "📦 Enabling NGINX Ingress addon..."
    minikube addons enable ingress
else
    echo "✅ NGINX Ingress addon is already enabled"
fi

echo "🐳 Building Docker image..."
# Point Docker to Minikube's Docker daemon
eval $(minikube docker-env)

# Build the Docker image
docker build -t asasikumar/express-mongo-minikube:latest .

echo "📋 Deploying application to Kubernetes..."
# Apply all Kubernetes manifests
kubectl apply -f k8s/

echo "⏳ Waiting for pods to be ready..."
# Wait for MongoDB to be ready
kubectl wait --namespace express-mongo-app \
    --for=condition=ready pod \
    --selector=app=mongo \
    --timeout=300s

# Wait for Express.js pods to be ready
kubectl wait --namespace express-mongo-app \
    --for=condition=ready pod \
    --selector=app=express-app \
    --timeout=300s

echo "🌐 Getting Minikube IP address..."
# Get Minikube IP for external access
MINIKUBE_IP=$(minikube ip)
echo "   Minikube IP: $MINIKUBE_IP"

echo "🔍 Checking application status..."
# Show pod status
kubectl get pods -n express-mongo-app

# Show service status
kubectl get services -n express-mongo-app

# Show ingress status
kubectl get ingress -n express-mongo-app

echo ""
echo "🎉 Setup complete! Your application is now accessible:"
echo ""
echo "   🌐 External Access (via Ingress):"
echo "      http://$MINIKUBE_IP"
echo ""
echo "   🔗 Local Access (via Port Forward):"
echo "      kubectl port-forward -n express-mongo-app service/express-app-service 8080:80"
echo "      Then visit: http://localhost:8080"
echo ""
echo "   📊 Kubernetes Dashboard:"
echo "      minikube dashboard"
echo ""
echo "   🔧 Useful Commands:"
echo "   - View logs: kubectl logs -f -n express-mongo-app deployment/express-app"
echo "   - Check ingress: kubectl describe ingress express-app-ingress -n express-mongo-app"
echo "   - Port forward: kubectl port-forward -n express-mongo-app service/express-app-service 8080:80" 