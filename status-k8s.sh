#!/bin/bash

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"
source "$SCRIPT_DIR/scripts/config.sh"



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
    echo "  -c, --config          Show configuration"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show basic status"
    echo "  $0 --detailed         # Show detailed information"
    echo "  $0 --pods             # Show only pod status"
    echo "  $0 --fast             # Fast mode (port forwarding only)"
    echo "  $0 --config           # Show configuration"
    echo "  $0 --help             # Show this help message"
}

# Parse command line arguments
DETAILED=false
SHOW_PODS=false
SHOW_SERVICES=false
SHOW_INGRESS=false
FAST_MODE=false
SHOW_CONFIG=false

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
        -c|--config)
            SHOW_CONFIG=true
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

# Show configuration if requested
if [ "$SHOW_CONFIG" = true ]; then
    print_config
    exit 0
fi

show_script_header "Kubernetes Status" "Checking Apollo Supergraph resources in minikube"

# Check if minikube is running (skip in fast mode)
if [ "$FAST_MODE" = false ]; then
    print_status "Checking minikube status..."
    if minikube_is_running; then
        print_success "Minikube is running"
        MINIKUBE_IP=$(get_minikube_ip)
        print_status "Minikube IP: $MINIKUBE_IP"
    else
        print_error "Minikube is not running. Please start minikube first:"
        echo "  minikube start"
        echo "  or run: ./setup-minikube.sh"
        echo ""
        echo "🌐 Access URLs (if services are running locally):"
        echo "  Router GraphQL:     $(get_router_graphql_url)"
        echo "  Router Health:      $(get_router_health_url)"
        echo "  Subgraphs:          $(get_subgraphs_url)"
        echo ""
        show_script_footer "Kubernetes Status"
        exit 0
    fi

    # Check if namespace exists
    NAMESPACE=$(get_k8s_namespace)
    print_status "Checking namespace..."
    if namespace_exists "$NAMESPACE"; then
        print_success "Namespace '$NAMESPACE' exists"
    else
        print_warning "Namespace '$NAMESPACE' does not exist"
        echo "  Run: ./run-k8s.sh to deploy the supergraph"
        echo ""
        echo "🌐 Access URLs (if services are running locally):"
        echo "  Router GraphQL:     $(get_router_graphql_url)"
        echo "  Router Health:      $(get_router_health_url)"
        echo "  Subgraphs:          $(get_subgraphs_url)"
        echo ""
        show_script_footer "Kubernetes Status"
        exit 0
    fi
    echo ""
fi

# Show pod status
if [ "$SHOW_PODS" = true ] || [ "$FAST_MODE" = false ]; then
    print_status "Pod Status:"
    echo ""
    run_with_timeout 10 kubectl get pods -n "$NAMESPACE" || echo "No pods found or timeout"
    echo ""
fi

# Show service status
if [ "$SHOW_SERVICES" = true ] || [ "$FAST_MODE" = false ]; then
    print_status "Service Status:"
    echo ""
    run_with_timeout 10 kubectl get services -n "$NAMESPACE" || echo "No services found or timeout"
    echo ""
fi

# Show deployment status
if [ "$FAST_MODE" = false ]; then
    print_status "Deployment Status:"
    echo ""
    run_with_timeout 10 kubectl get deployments -n "$NAMESPACE" || echo "No deployments found or timeout"
    echo ""
fi

# Show ingress status
if [ "$SHOW_INGRESS" = true ] || [ "$FAST_MODE" = false ]; then
    print_status "Ingress Status:"
    echo ""
    run_with_timeout 10 kubectl get ingress -n "$NAMESPACE" || echo "No ingress found or timeout"
    echo ""
fi

# Show port forwarding status (always show this)
print_status "Port Forwarding Status:"
echo ""
if is_port_forwarded "$ROUTER_GRAPHQL_PORT"; then
    print_success "Port $ROUTER_GRAPHQL_PORT is being forwarded (router)"
else
    print_warning "Port $ROUTER_GRAPHQL_PORT is not being forwarded"
fi

if is_port_forwarded "$SUBGRAPHS_PORT"; then
    print_success "Port $SUBGRAPHS_PORT is being forwarded (subgraphs)"
else
    print_warning "Port $SUBGRAPHS_PORT is not being forwarded"
fi
echo ""

# Show access URLs
print_status "Access URLs:"
echo ""
echo "  Router GraphQL:     $(get_router_graphql_url)"
echo "  Router Health:      $(get_router_health_url)"
echo "  Subgraphs:          $(get_subgraphs_url)"
echo "  Minikube Dashboard: minikube dashboard"
echo ""

# Show detailed information if requested
if [ "$DETAILED" = true ] && [ "$FAST_MODE" = false ]; then
    print_status "Detailed Information:"
    echo ""
    
    # Show recent events
    print_status "Recent Events:"
    run_with_timeout 5 kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -5 || echo "Events not available"
    echo ""
    
    # Show resource usage (if metrics server available)
    print_status "Resource Usage:"
    run_with_timeout 5 kubectl top pods -n "$NAMESPACE" || echo "Metrics server not available"
    echo ""
fi

# Show manual commands
if [ "$FAST_MODE" = false ]; then
    print_status "Manual Status Commands:"
    echo "  - Check minikube: minikube status"
    echo "  - View pods: kubectl get pods -n $NAMESPACE"
    echo "  - View services: kubectl get svc -n $NAMESPACE"
    echo "  - View deployments: kubectl get deployments -n $NAMESPACE"
    echo "  - Test router: ./test-router.sh"
    echo ""
fi

show_script_footer "Kubernetes Status"
