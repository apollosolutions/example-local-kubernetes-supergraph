#!/bin/bash

set -e

echo "🧪 Testing router-only deployment..."

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
    print_error "Namespace router-only does not exist. Please deploy first:"
    echo "  ./deploy-router-only.sh"
    exit 1
fi

# Check if pods are running
print_status "Checking pod status..."
PODS=$(kubectl get pods -n router-only -o jsonpath='{.items[*].status.phase}')
RUNNING_PODS=$(echo $PODS | grep -o "Running" | wc -l)
TOTAL_PODS=$(echo $PODS | wc -w)

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    print_success "All $TOTAL_PODS pods are running"
else
    print_error "Only $RUNNING_PODS/$TOTAL_PODS pods are running"
    kubectl get pods -n router-only
    exit 1
fi

# Check if service is ready
print_status "Checking service status..."
kubectl get svc -n router-only

# Test router health via port-forward
print_status "Testing router health via port-forward..."
kubectl port-forward svc/apollo-router-service 4000:4000 -n router-only &
PF_PID=$!

# Wait for port-forward to be ready
sleep 5

# Test router health
if curl -s http://localhost:4000 > /dev/null; then
    print_success "Router is responding"
else
    print_error "Router is not responding"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test GraphQL introspection
print_status "Testing GraphQL introspection..."
RESPONSE=$(curl -s -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { fields { name } } } }"}')

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL introspection successful"
    echo "Available fields:"
    echo "$RESPONSE" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g' | head -10
else
    print_error "GraphQL introspection failed"
    echo "Response: $RESPONSE"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test a GraphQL query (this will fail if subgraphs aren't available, but router should start)
print_status "Testing GraphQL query (may fail if subgraphs not available)..."
RESPONSE=$(curl -s -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ products { id title } }"}')

if echo "$RESPONSE" | grep -q "data\|errors"; then
    print_success "GraphQL query executed (router is working)"
    if echo "$RESPONSE" | grep -q "errors"; then
        print_warning "Query returned errors (expected if subgraphs not available)"
        echo "Error details: $RESPONSE" | head -c 200
        echo "..."
    else
        print_success "Query returned data successfully"
    fi
else
    print_error "GraphQL query failed completely"
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
echo "  ✅ Service is configured"
echo "  ✅ Router is responding"
echo "  ✅ GraphQL introspection works"
echo "  ✅ GraphQL queries are processed"
echo ""
echo "🌐 Your Apollo Router is ready!"
echo "  - Use: minikube service apollo-router-service -n router-only"
echo "  - Or port-forward: kubectl port-forward svc/apollo-router-service 4000:4000 -n router-only"
echo ""
echo "⚠️  Note: Router is configured to connect to subgraphs at localhost:4001"
echo "   To test full functionality, you need subgraphs running locally or via port-forward"
