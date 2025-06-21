#!/bin/bash

# Simple stop script for daily use
# Stops port-forwarding and Minikube without deleting anything

echo "🛑 Stopping Express.js + MongoDB on Minikube..."

# Stop all port-forwarding processes
echo "📡 Stopping port-forwarding processes..."
pkill -f "kubectl port-forward" 2>/dev/null || echo "No port-forwarding processes found"

# Stop Minikube (keeps all data)
echo "🛑 Stopping Minikube (saving resources, keeping all data)..."
minikube stop

echo ""
echo "✅ Stopped successfully!"
echo "💾 All data preserved - you can restart anytime with:"
echo "   minikube start"
echo "   ./deploy-app.sh" 