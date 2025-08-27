#!/bin/bash

set -e

echo "🚀 Deploying Apollo Router to minikube..."

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

# Apply the router-only deployment with environment variable substitution
print_status "Deploying Apollo Router to minikube..."
envsubst < k8s/router-only-deployment.yaml | kubectl apply -f -

# Wait for router to be ready
print_status "Waiting for Apollo Router to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/apollo-router -n router-only

# Get minikube IP
MINIKUBE_IP=$(minikube ip)

print_success "Apollo Router deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  - Namespace: router-only"
echo "  - Apollo Router: 1 replica"
echo "  - Service Type: NodePort"
echo "  - GraphQL NodePort: 30400"
echo "  - Health NodePort: 30408"
echo ""
echo "🌐 Access your Apollo Router:"
echo "  - Use: minikube service apollo-router-service -n router-only"
echo "  - GraphQL: http://localhost:30400/graphql (after running minikube service command)"
echo "  - Health: http://localhost:30408/health"
echo ""
echo "🔍 Useful commands:"
echo "  - View pods: kubectl get pods -n router-only"
echo "  - View service: kubectl get svc -n router-only"
echo "  - View logs: kubectl logs -f deployment/apollo-router -n router-only"
echo "  - Port forward: kubectl port-forward svc/apollo-router-service 4000:4000 -n router-only"
echo ""
echo "⚠️  Note: Router is configured to connect to subgraphs at localhost:4001"
echo "   This will only work if you have subgraphs running locally or via port-forward"
