#!/bin/bash

set -e

echo "🧹 Cleaning up Apollo Supergraph deployment..."

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

# Check if namespace exists
if ! kubectl get namespace apollo-supergraph > /dev/null 2>&1; then
    print_warning "Namespace apollo-supergraph does not exist. Nothing to clean up."
    exit 0
fi

print_status "Removing all resources from apollo-supergraph namespace..."

# Delete all resources in the namespace
kubectl delete namespace apollo-supergraph

print_success "Cleanup completed successfully!"
echo ""
echo "📋 Cleanup Summary:"
echo "  - Removed namespace: apollo-supergraph"
echo "  - Removed all deployments, services, and configmaps"
echo "  - Removed ingress configuration"
echo ""
print_warning "Remember to remove the following line from your /etc/hosts file if you added it:"
echo "  <minikube-ip> apollo-router.local"
