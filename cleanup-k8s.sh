#!/bin/bash

set -e

# Source shared utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# If SCRIPT_DIR is the root directory, we need to source from scripts subdirectory
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
    source "$SCRIPT_DIR/utils.sh"
    source "$SCRIPT_DIR/config.sh"
else
    source "$SCRIPT_DIR/scripts/utils.sh"
    source "$SCRIPT_DIR/scripts/config.sh"
fi

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
cleanup_namespace "$(get_k8s_namespace)" "Apollo Supergraph"

print_success "Cleanup completed successfully!"
echo ""
echo "📋 Cleanup Summary:"
echo "  - Cleaned namespace: $(get_k8s_namespace)"
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
