#!/bin/bash

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

show_script_header "Minikube Cleanup" "Killing minikube for Apollo Supergraph cleanup"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --stop-only      Stop minikube but keep the cluster (can be restarted)"
    echo "  -d, --delete         Stop and delete the minikube cluster completely (default)"
    echo "  -f, --force          Force deletion without confirmation"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Stop and delete cluster (default)"
    echo "  $0 --stop-only       # Stop but keep cluster"
    echo "  $0 --delete          # Stop and delete cluster"
    echo "  $0 --force           # Force delete without confirmation"
    echo "  $0 -s                # Stop only (short form)"
    echo "  $0 -d                # Delete (short form)"
    echo "  $0 -f                # Force delete (short form)"
}

# Default values
STOP_ONLY=false
DELETE_CLUSTER=true
FORCE_DELETE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--stop-only)
            STOP_ONLY=true
            DELETE_CLUSTER=false
            shift
            ;;
        -d|--delete)
            STOP_ONLY=false
            DELETE_CLUSTER=true
            shift
            ;;
        -f|--force)
            FORCE_DELETE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if minikube is installed
if ! minikube_is_installed; then
    print_error "minikube is not installed. Nothing to kill."
    exit 1
fi

print_success "minikube is installed"

# Check if minikube cluster exists
if ! minikube status &> /dev/null; then
    print_warning "No minikube cluster found. Nothing to kill."
    exit 0
fi

# Show current status
print_status "Current minikube status:"
minikube status

echo ""

# Determine action based on options
if [ "$STOP_ONLY" = true ]; then
    print_status "Stopping minikube cluster (keeping data)..."
    minikube stop
    print_success "minikube stopped successfully!"
    echo ""
    echo "📋 Stop Summary:"
    echo "  - minikube cluster stopped"
    echo "  - Cluster data preserved"
    echo "  - Can be restarted with: minikube start"
    echo ""
    echo "🔍 Useful commands:"
    echo "  - Start minikube: minikube start"
    echo "  - Delete cluster: minikube delete"
    echo "  - View status: minikube status"
else
    # Delete cluster
    if [ "$FORCE_DELETE" = false ]; then
        echo ""
        print_warning "This will completely delete the minikube cluster and all its data!"
        echo "This action cannot be undone."
        echo ""
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled."
            exit 0
        fi
    fi
    
    print_status "Stopping minikube cluster..."
    minikube stop
    
    print_status "Deleting minikube cluster..."
    minikube delete
    
    print_success "minikube cluster deleted successfully!"
    echo ""
    echo "📋 Deletion Summary:"
    echo "  - minikube cluster stopped"
    echo "  - All cluster data deleted"
    echo "  - All containers removed"
    echo "  - All configurations cleared"
    echo ""
    echo "🚀 To start fresh:"
    echo "  ./setup-minikube.sh"
    echo ""
    echo "🔍 Useful commands:"
    echo "  - Setup minikube: ./setup-minikube.sh"
    echo "  - Check if minikube exists: minikube status"
fi

show_script_footer "Minikube Cleanup"
