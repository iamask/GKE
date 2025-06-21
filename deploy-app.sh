#!/bin/bash

# This script automates the deployment process for the Express.js + MongoDB application on Minikube.
# It handles the complete workflow from building the Docker image to making the app accessible.
# 
# Why this file exists:
# - Eliminates manual steps and reduces deployment errors
# - Ensures consistent deployment process across different environments
# - Provides interactive options for port-forwarding
# - Saves time by automating repetitive tasks
# - Ensures metrics server is always enabled for monitoring

set -e  # Exit immediately if any command fails

# Configuration variables - easily modifiable for different environments
NAMESPACE="express-mongo-app"
IMAGE="asasikumar/express-mongo-minikube:latest"

echo "🔧 Ensuring Minikube is running with required addons..."
# Check if Minikube is running
if ! minikube status | grep -q "Running"; then
    echo "🚀 Starting Minikube with required addons..."
    minikube start --addons=ingress,metrics-server
else
    echo "✅ Minikube is already running"
    # Ensure metrics-server is enabled
    if ! minikube addons list | grep -q "metrics-server.*enabled"; then
        echo "📊 Enabling metrics-server addon..."
        minikube addons enable metrics-server
    else
        echo "✅ Metrics server is already enabled"
    fi
fi

echo "👉 Switching Docker to Minikube's Docker daemon..."
# This is crucial for Minikube - it ensures the Docker image is built inside Minikube's Docker daemon
# so Kubernetes can find and use the local image without pulling from external registries
eval $(minikube docker-env)

echo "🐳 Building Docker image: $IMAGE"
# Build the production-ready Docker image with the latest code changes
docker build -t $IMAGE .

echo "📊 Ensuring metrics server is ready..."
# Wait for metrics server to be ready before proceeding
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

echo "🔄 Restarting Express.js deployment in namespace $NAMESPACE"
# Force a rolling restart to pick up the new Docker image
# This is more reliable than deleting/recreating pods
kubectl rollout restart deployment/express-app -n $NAMESPACE

echo "⏳ Waiting for pods to be ready..."
# Wait for the new pods to be fully ready before proceeding
# This prevents issues where the app might not be fully functional yet
kubectl wait --for=condition=ready pod -l app=express-app -n $NAMESPACE --timeout=300s

echo "📈 Generating some load to create initial metrics..."
# Generate some load to ensure metrics are available
for i in {1..5}; do
    curl -s http://localhost:8080/ > /dev/null 2>&1 || true
    sleep 1
done

echo "✅ Deployment complete!"

# Show current metrics
echo "📊 Current resource usage:"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics will be available in a few minutes..."

# Interactive port-forwarding option
# This makes it easy to immediately test the application after deployment
read -p 'Do you want to port-forward to localhost:8080? (y/n): ' answer
if [[ $answer == [Yy]* ]]; then
  echo "🌐 Port-forwarding service/express-app-service 8080:80"
  # Forward the Kubernetes service to localhost for easy testing
  kubectl port-forward -n $NAMESPACE service/express-app-service 8080:80
else
  echo "You can port-forward later with:"
  echo "kubectl port-forward -n $NAMESPACE service/express-app-service 8080:80"
fi 