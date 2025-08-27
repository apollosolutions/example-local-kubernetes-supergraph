#!/bin/bash

set -e

echo "🔧 Setting up minikube for Apollo Supergraph deployment..."

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

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    print_error "minikube is not installed. Please install minikube first:"
    echo "  https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

print_success "minikube is installed"

# Start minikube if not running
if ! minikube status | grep -q "Running"; then
    print_status "Starting minikube..."
    minikube start --memory=4096 --cpus=2 --disk-size=20g
    print_success "minikube started"
else
    print_success "minikube is already running"
fi

# Enable ingress addon
print_status "Enabling ingress addon..."
minikube addons enable ingress

# Wait for ingress to be ready
print_status "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

print_success "Ingress controller is ready"

# Enable metrics server (optional, for better monitoring)
print_status "Enabling metrics server..."
minikube addons enable metrics-server

print_success "minikube setup completed!"
echo ""
echo "📋 Setup Summary:"
echo "  - minikube cluster started"
echo "  - Ingress controller enabled"
echo "  - Metrics server enabled"
echo ""
echo "🚀 You can now run the deployment:"
echo "  ./deploy.sh"
echo ""
echo "🔍 Useful commands:"
echo "  - Open minikube dashboard: minikube dashboard"
echo "  - Get minikube IP: minikube ip"
echo "  - SSH into minikube: minikube ssh"
