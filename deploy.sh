#!/bin/bash

set -e

echo "🚀 Starting Apollo Supergraph deployment to minikube..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    print_error "Minikube is not running. Please start minikube first:"
    echo "  minikube start"
    exit 1
fi

print_success "Minikube is running"

# Source environment variables from .env file
if [ -f "router/.env" ]; then
    print_status "Loading environment variables from router/.env"
    export $(cat router/.env | grep -v '^#' | xargs)
else
    print_error "router/.env file not found. Please create it with APOLLO_KEY and APOLLO_GRAPH_REF"
    exit 1
fi

# Verify required environment variables are set
if [ -z "$APOLLO_KEY" ] || [ -z "$APOLLO_GRAPH_REF" ]; then
    print_error "APOLLO_KEY and APOLLO_GRAPH_REF must be set in router/.env"
    exit 1
fi

print_status "Using APOLLO_GRAPH_REF: $APOLLO_GRAPH_REF"

# Check if Docker is available in minikube
if ! minikube docker-env > /dev/null 2>&1; then
    print_error "Cannot get minikube Docker environment"
    exit 1
fi

# Set Docker environment to use minikube's Docker daemon
eval $(minikube docker-env)

print_status "Building subgraphs Docker image..."

# Build the subgraphs Docker image
cd subgraphs
docker build -t subgraphs:latest .
cd ..

print_success "Subgraphs Docker image built successfully"

# Create namespace
print_status "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMaps
print_status "Applying ConfigMaps..."
kubectl apply -f k8s/configmaps.yaml

# Deploy subgraphs first
print_status "Deploying subgraphs..."
kubectl apply -f k8s/subgraphs-deployment.yaml

# Wait for subgraphs to be ready
print_status "Waiting for subgraphs to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/subgraphs -n apollo-supergraph

# Deploy Apollo Router with environment variable substitution
print_status "Deploying Apollo Router..."
envsubst < k8s/router-deployment.yaml | kubectl apply -f -

# Wait for router to be ready
print_status "Waiting for Apollo Router to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/apollo-router -n apollo-supergraph

# Apply Ingress
print_status "Applying Ingress configuration..."
kubectl apply -f k8s/ingress.yaml

# Wait for ingress to be ready
print_status "Waiting for Ingress to be ready..."
sleep 10

# Get minikube IP
MINIKUBE_IP=$(minikube ip)

print_success "Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  - Namespace: apollo-supergraph"
echo "  - Subgraphs: 2 replicas"
echo "  - Apollo Router: 2 replicas"
echo "  - Ingress: apollo-router.local"
echo ""
echo "🌐 Access your applications:"
echo "  - Apollo Router: http://apollo-router.local (add to /etc/hosts: $MINIKUBE_IP apollo-router.local)"
echo "  - Router Health: http://$MINIKUBE_IP:$(kubectl get svc apollo-router-service -n apollo-supergraph -o jsonpath='{.spec.ports[?(@.name=="health")].nodePort}')"
echo ""
echo "🔍 Useful commands:"
echo "  - View pods: kubectl get pods -n apollo-supergraph"
echo "  - View services: kubectl get svc -n apollo-supergraph"
echo "  - View logs: kubectl logs -f deployment/apollo-router -n apollo-supergraph"
echo "  - Port forward: kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph"
echo ""
print_warning "Don't forget to add the following line to your /etc/hosts file:"
echo "  $MINIKUBE_IP apollo-router.local"
