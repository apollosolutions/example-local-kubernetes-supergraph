#!/bin/bash

set -e

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
    echo ""
    echo "Examples:"
    echo "  $0                    # Test Apollo Supergraph deployment"
    echo "  $0 --help             # Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

show_script_header "Apollo Supergraph Kubernetes Testing" "Testing Apollo Supergraph deployment in minikube"

# Get namespace
NAMESPACE=$(get_k8s_namespace)

# Check if namespace exists
if ! namespace_exists "$NAMESPACE"; then
    print_error "Namespace $NAMESPACE does not exist. Please deploy first:"
    echo "  ./run-k8s.sh"
    exit 1
fi

# Check if pods are running
print_status "Checking pod status in namespace: $NAMESPACE..."
PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].status.phase}')
RUNNING_PODS=$(echo $PODS | grep -o "Running" | wc -l)
TOTAL_PODS=$(echo $PODS | wc -w)

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    print_success "All $TOTAL_PODS pods are running"
else
    print_error "Only $RUNNING_PODS/$TOTAL_PODS pods are running"
    kubectl get pods -n $NAMESPACE
    exit 1
fi

# Check if services are ready
print_status "Checking service status..."
kubectl get svc -n $NAMESPACE

# Source port forwarding utilities
source "$SCRIPT_DIR/scripts/port-forward-utils.sh"

# Test subgraphs
print_status "Testing subgraphs health..."

# Start subgraphs port forwarding
if start_subgraphs_port_forward; then
    if curl -s "$(get_subgraphs_products_url)" > /dev/null; then
        print_success "Subgraphs are responding"
    else
        print_error "Subgraphs are not responding"
        stop_port_forward "subgraphs"
        exit 1
    fi

    # Test GraphQL query to subgraphs
    print_status "Testing GraphQL query to subgraphs..."
    RESPONSE=$(curl -s -X POST "$(get_subgraphs_products_url)" \
      -H "Content-Type: application/json" \
      -d '{"query":"{ searchProducts { id title price } }"}')

    # Stop subgraphs port forwarding
    stop_port_forward "subgraphs"
else
    print_error "Failed to start subgraphs port forwarding"
    exit 1
fi

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL query to subgraphs successful"
    echo "Response: $RESPONSE" | head -c 200
    echo "..."
else
    print_error "GraphQL query to subgraphs failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Source test utilities for router testing
source "$SCRIPT_DIR/scripts/test-utils.sh"

# Test router
print_status "Testing router health..."

# Start router port forwarding
if start_router_port_forward; then
    if test_router_health > /dev/null 2>&1; then
        print_success "Router is responding"
    else
        print_error "Router is not responding"
        stop_port_forward "apollo-router"
        exit 1
    fi

    # Test GraphQL query to router
    print_status "Testing GraphQL query to router..."
    if test_search_products > /dev/null 2>&1; then
        print_success "GraphQL query to router successful"
    else
        print_error "GraphQL query to router failed"
        stop_port_forward "apollo-router"
        exit 1
    fi
    
    # Stop router port forwarding
    stop_port_forward "apollo-router"
else
    print_error "Failed to start router port forwarding"
    exit 1
fi

print_success "All tests passed! 🎉"
echo ""
echo "📋 Test Summary:"
echo "  - Namespace: $NAMESPACE"
echo "  ✅ All pods are running"
echo "  ✅ Services are configured"
echo "  ✅ Subgraphs are responding"
echo "  ✅ GraphQL queries to subgraphs work"
echo "  ✅ Router is responding"
echo "  ✅ GraphQL queries to router work"

echo ""
echo "🌐 Your deployment is ready!"
echo "  - Router: kubectl port-forward svc/$(get_router_service_name) $ROUTER_GRAPHQL_PORT:$ROUTER_GRAPHQL_PORT -n $NAMESPACE"
echo "  - Subgraphs: kubectl port-forward svc/$(get_subgraphs_service_name) $SUBGRAPHS_PORT:$SUBGRAPHS_PORT -n $NAMESPACE"

show_script_footer "Kubernetes Testing"
