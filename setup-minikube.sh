#!/bin/bash

set -e

# Source shared utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# If SCRIPT_DIR is the root directory, we need to source from scripts subdirectory
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    source "$SCRIPT_DIR/scripts/utils.sh"
fi

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup minikube for Apollo Supergraph deployment.

OPTIONS:
    -h, --help    Show this help message and exit

EXAMPLES:
    $0              # Setup minikube with default settings
    $0 --help       # Show this help message

DESCRIPTION:
    This script sets up a minikube cluster with:
    - 4GB memory, 2 CPUs, 20GB disk
    - Ingress controller enabled
    - Metrics server enabled
    
    After setup, you can run ./run-k8s.sh to deploy the supergraph.

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

show_script_header "Minikube Setup" "Setting up minikube for Apollo Supergraph deployment"

# Validate required tools
if ! validate_required_tools; then
    exit 1
fi

print_success "All required tools are installed"

# Start minikube if not running
if ! minikube_is_running; then
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
echo "  ./run-k8s.sh"
echo ""
echo "🔍 Useful commands:"
echo "  - Open minikube dashboard: minikube dashboard"
echo "  - Get minikube IP: minikube ip"
echo "  - SSH into minikube: minikube ssh"

show_script_footer "Minikube Setup"
