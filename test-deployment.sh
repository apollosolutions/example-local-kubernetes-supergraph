#!/bin/bash

set -e

echo "🧪 Testing Apollo Supergraph deployment..."

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
    print_error "Namespace apollo-supergraph does not exist. Please deploy first:"
    echo "  ./deploy.sh"
    exit 1
fi

# Check if pods are running
print_status "Checking pod status..."
PODS=$(kubectl get pods -n apollo-supergraph -o jsonpath='{.items[*].status.phase}')
RUNNING_PODS=$(echo $PODS | grep -o "Running" | wc -l)
TOTAL_PODS=$(echo $PODS | wc -w)

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    print_success "All $TOTAL_PODS pods are running"
else
    print_error "Only $RUNNING_PODS/$TOTAL_PODS pods are running"
    kubectl get pods -n apollo-supergraph
    exit 1
fi

# Check if services are ready
print_status "Checking service status..."
kubectl get svc -n apollo-supergraph

# Test subgraphs health via port-forward
print_status "Testing subgraphs health..."
kubectl port-forward svc/subgraphs-service 4001:4001 -n apollo-supergraph &
PF_PID=$!

# Wait for port-forward to be ready
sleep 5

# Test subgraphs
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
  -d '{"query":"{ products { id title price } }"}')

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL query to subgraphs successful"
    echo "Response: $RESPONSE" | head -c 200
    echo "..."
else
    print_error "GraphQL query to subgraphs failed"
    echo "Response: $RESPONSE"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Stop port-forward
kill $PF_PID 2>/dev/null || true

# Test router health via port-forward
print_status "Testing router health..."
kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph &
PF_PID=$!

# Wait for port-forward to be ready
sleep 5

# Test router
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
  -d '{"query":"{ products { id title price } }"}')

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL query to router successful"
    echo "Response: $RESPONSE" | head -c 200
    echo "..."
else
    print_error "GraphQL query to router failed"
    echo "Response: $RESPONSE"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Stop port-forward
kill $PF_PID 2>/dev/null || true

print_success "All tests passed! 🎉"
echo ""
echo "📋 Test Summary:"
echo "  ✅ All pods are running"
echo "  ✅ Services are configured"
echo "  ✅ Subgraphs are responding"
echo "  ✅ Router is responding"
echo "  ✅ GraphQL queries work"
echo ""
echo "🌐 Your Apollo Supergraph is ready!"
echo "  - Router: http://apollo-router.local (if /etc/hosts configured)"
echo "  - Health: kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph"
