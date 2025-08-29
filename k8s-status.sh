#!/bin/bash

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message"
    echo "  -d, --detailed        Show detailed resource information"
    echo "  -p, --pods            Show only pod status"
    echo "  -s, --services        Show only service status"
    echo "  -i, --ingress         Show only ingress status"
    echo "  -f, --fast            Fast mode (skip minikube checks)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show basic status"
    echo "  $0 --detailed         # Show detailed information"
    echo "  $0 --pods             # Show only pod status"
    echo "  $0 --fast             # Fast mode (port forwarding only)"
    echo "  $0 --help             # Show this help message"
}

# Parse command line arguments
DETAILED=false
SHOW_PODS=false
SHOW_SERVICES=false
SHOW_INGRESS=false
FAST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -p|--pods)
            SHOW_PODS=true
            shift
            ;;
        -s|--services)
            SHOW_SERVICES=true
            shift
            ;;
        -i|--ingress)
            SHOW_INGRESS=true
            shift
            ;;
        -f|--fast)
            FAST_MODE=true
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            print_error "Unknown argument: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo "============================================================================="
echo "Apollo Supergraph - Kubernetes Status"
echo "============================================================================="
echo "Checking Apollo Supergraph resources in minikube"
echo "============================================================================="
echo ""

# Check if minikube is running (skip in fast mode)
if [ "$FAST_MODE" = false ]; then
    print_status "Checking minikube status..."
    if run_with_timeout 5 minikube status | grep -q "Running" 2>/dev/null; then
        print_success "Minikube is running"
        MINIKUBE_IP=$(run_with_timeout 3 minikube ip 2>/dev/null || echo "unknown")
        print_status "Minikube IP: $MINIKUBE_IP"
    else
        print_error "Minikube is not running or not accessible"
        echo "  Run: minikube start"
        echo "  or run: ./setup-minikube.sh"
        echo ""
        echo "🌐 Access URLs (if services are running locally):"
        echo "  Router GraphQL:     http://localhost:4000/graphql"
        echo "  Router Health:      http://localhost:4000/health"
        echo "  Subgraphs:          http://localhost:4001"
        echo ""
        echo "============================================================================="
        echo "Kubernetes Status completed!"
        echo "============================================================================="
        exit 0
    fi

    # Check if namespace exists
    NAMESPACE="apollo-supergraph"
    print_status "Checking namespace..."
    if run_with_timeout 5 kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
        print_success "Namespace '$NAMESPACE' exists"
    else
        print_warning "Namespace '$NAMESPACE' does not exist"
        echo "  Run: ./run-k8s.sh to deploy the supergraph"
        echo ""
        echo "🌐 Access URLs (if services are running locally):"
        echo "  Router GraphQL:     http://localhost:4000/graphql"
        echo "  Router Health:      http://localhost:4000/health"
        echo "  Subgraphs:          http://localhost:4001"
        echo ""
        echo "============================================================================="
        echo "Kubernetes Status completed!"
        echo "============================================================================="
        exit 0
    fi
    echo ""
fi

# Show pod status
if [ "$SHOW_PODS" = true ] || [ "$FAST_MODE" = false ]; then
    echo "📦 Pod Status:"
    echo ""
    run_with_timeout 10 kubectl get pods -n "$NAMESPACE" || echo "No pods found or timeout"
    echo ""
fi

# Show service status
if [ "$SHOW_SERVICES" = true ] || [ "$FAST_MODE" = false ]; then
    echo "🔌 Service Status:"
    echo ""
    run_with_timeout 10 kubectl get services -n "$NAMESPACE" || echo "No services found or timeout"
    echo ""
fi

# Show deployment status
if [ "$FAST_MODE" = false ]; then
    echo "🚀 Deployment Status:"
    echo ""
    run_with_timeout 10 kubectl get deployments -n "$NAMESPACE" || echo "No deployments found or timeout"
    echo ""
fi

# Show ingress status
if [ "$SHOW_INGRESS" = true ] || [ "$FAST_MODE" = false ]; then
    echo "🌐 Ingress Status:"
    echo ""
    run_with_timeout 10 kubectl get ingress -n "$NAMESPACE" || echo "No ingress found or timeout"
    echo ""
fi

# Show port forwarding status (always show this)
echo "🔗 Port Forwarding Status:"
echo ""
if lsof -i :4000 > /dev/null 2>&1; then
    print_success "Port 4000 is being forwarded (router)"
else
    print_warning "Port 4000 is not being forwarded"
fi

if lsof -i :4001 > /dev/null 2>&1; then
    print_success "Port 4001 is being forwarded (subgraphs)"
else
    print_warning "Port 4001 is not being forwarded"
fi
echo ""

# Show access URLs
echo "🌐 Access URLs:"
echo ""
echo "  Router GraphQL:     http://localhost:4000/graphql"
echo "  Router Health:      http://localhost:4000/health"
echo "  Subgraphs:          http://localhost:4001"
echo "  Minikube Dashboard: minikube dashboard"
echo ""

# Show detailed information if requested
if [ "$DETAILED" = true ] && [ "$FAST_MODE" = false ]; then
    echo "📊 Detailed Information:"
    echo ""
    
    # Show recent events
    echo "📋 Recent Events:"
    run_with_timeout 5 kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -5 || echo "Events not available"
    echo ""
    
    # Show resource usage (if metrics server available)
    echo "💾 Resource Usage:"
    run_with_timeout 5 kubectl top pods -n "$NAMESPACE" || echo "Metrics server not available"
    echo ""
fi

# Show manual commands
if [ "$FAST_MODE" = false ]; then
    echo "🔍 Manual Status Commands:"
    echo "  - Check minikube: minikube status"
    echo "  - View pods: kubectl get pods -n apollo-supergraph"
    echo "  - View services: kubectl get svc -n apollo-supergraph"
    echo "  - View deployments: kubectl get deployments -n apollo-supergraph"
    echo "  - Test router: ./test-router.sh"
    echo ""
fi

echo "============================================================================="
echo "Kubernetes Status completed successfully!"
echo "============================================================================="
