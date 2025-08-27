#!/bin/bash

set -e

echo "🧹 Cleaning up router-only deployment..."

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
if ! kubectl get namespace router-only > /dev/null 2>&1; then
    print_warning "Namespace router-only does not exist. Nothing to clean up."
    exit 0
fi

print_status "Removing router-only namespace and all resources..."

# Delete the namespace (this will remove all resources in it)
kubectl delete namespace router-only

print_success "Cleanup completed successfully!"
echo ""
echo "📋 Cleanup Summary:"
echo "  - Removed namespace: router-only"
echo "  - Removed Apollo Router deployment"
echo "  - Removed Apollo Router service"
echo "  - Removed ConfigMaps"
