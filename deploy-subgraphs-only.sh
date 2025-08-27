#!/bin/bash

set -e

echo "🚀 Deploying subgraphs app to minikube..."

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

# Apply the subgraphs-only deployment
print_status "Deploying subgraphs to minikube..."
kubectl apply -f k8s/subgraphs-only-deployment.yaml

# Wait for subgraphs to be ready
print_status "Waiting for subgraphs to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/subgraphs -n subgraphs-only

# Get minikube IP
MINIKUBE_IP=$(minikube ip)

print_success "Subgraphs deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  - Namespace: subgraphs-only"
echo "  - Subgraphs: 1 replica"
echo "  - Service Type: NodePort"
echo "  - NodePort: 30401"
echo ""
echo "🌐 Access your subgraphs application:"
echo "  - Use: minikube service subgraphs-service -n subgraphs-only"
echo "  - Products: http://localhost:30401/products/graphql (after running minikube service command)"
echo "  - Reviews: http://localhost:30401/reviews/graphql"
echo "  - Users: http://localhost:30401/users/graphql"
echo ""
echo "🔍 Useful commands:"
echo "  - View pods: kubectl get pods -n subgraphs-only"
echo "  - View service: kubectl get svc -n subgraphs-only"
echo "  - View logs: kubectl logs -f deployment/subgraphs -n subgraphs-only"
echo "  - Port forward: kubectl port-forward svc/subgraphs-service 4001:4001 -n subgraphs-only"
echo ""
echo "🧪 Test the deployment:"
echo "  curl -X POST http://$MINIKUBE_IP:30401/products/graphql \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"query\":\"{ products { id title price } }\"}'"
