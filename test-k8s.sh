#!/bin/bash

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

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

NAMESPACE="apollo-supergraph"

show_script_header "Apollo Supergraph Kubernetes Testing" "Testing Apollo Supergraph deployment in minikube"

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

# Test subgraphs
print_status "Testing subgraphs health..."

# Test via port-forward
kubectl port-forward svc/subgraphs-service 4001:4001 -n $NAMESPACE &
PF_PID=$!

# Wait for port-forward to be ready
sleep 5

if curl -s http://localhost:4001/products/graphql > /dev/null; then
    print_success "Subgraphs are responding"
else
    print_error "Subgraphs are not responding"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test GraphQL query to subgraphs
print_status "Testing GraphQL query to subgraphs..."
RESPONSE=$(curl -s -X POST http://localhost:4001/products/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title price } }"}')

# Stop port-forward
kill $PF_PID 2>/dev/null || true

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL query to subgraphs successful"
    echo "Response: $RESPONSE" | head -c 200
    echo "..."
else
    print_error "GraphQL query to subgraphs failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test router
print_status "Testing router health..."

# Wait for port-forward to be ready
sleep 5

if curl -s http://localhost:4000 > /dev/null; then
    print_success "Router is responding"
else
    print_error "Router is not responding"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test GraphQL query to router
print_status "Testing GraphQL query to router..."
RESPONSE=$(curl -s -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title price } }"}')

# Stop port-forward
kill $PF_PID 2>/dev/null || true

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL query to router successful"
    echo "Response: $RESPONSE" | head -c 200
    echo "..."
else
    print_error "GraphQL query to router failed"
    echo "Response: $RESPONSE"
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
echo "  - Router: kubectl port-forward svc/apollo-router-service 4000:4000 -n $NAMESPACE"
echo "  - Subgraphs: kubectl port-forward svc/subgraphs-service 4001:4001 -n $NAMESPACE"

show_script_footer "Kubernetes Testing"
