#!/bin/bash

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

show_script_header "Cleanup" "Cleaning up Apollo Supergraph from minikube"

# Function to cleanup namespace
cleanup_namespace() {
    local namespace=$1
    local description=$2
    
    if namespace_exists "$namespace"; then
        print_status "Cleaning up $description namespace: $namespace"
        kubectl delete namespace "$namespace" --ignore-not-found=true
        print_success "Cleaned up namespace: $namespace"
    else
        print_warning "Namespace $namespace does not exist, skipping..."
    fi
}

# Clean up the main namespace
cleanup_namespace "apollo-supergraph" "Apollo Supergraph"

print_success "Cleanup completed successfully!"
echo ""
echo "📋 Cleanup Summary:"
echo "  - Cleaned namespace: apollo-supergraph"
echo ""
echo "🔍 Verify cleanup:"
echo "  - View all namespaces: kubectl get namespaces"
echo "  - View all pods: kubectl get pods --all-namespaces"

echo ""
print_warning "Note: Minikube is still running!"
echo "  - Only the Apollo Supergraph pods and namespace were deleted"
echo "  - To stop minikube completely, run: ./kill-minikube.sh"
echo "  - To restart the deployment, run: ./run-k8s.sh"

show_script_footer "Cleanup"
