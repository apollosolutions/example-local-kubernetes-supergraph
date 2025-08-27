#!/bin/bash

set -e

echo "🔍 Validating external access to subgraphs deployment..."

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
if ! kubectl get namespace subgraphs-only > /dev/null 2>&1; then
    print_error "Namespace subgraphs-only does not exist. Please deploy first:"
    echo "  ./deploy-subgraphs-only.sh"
    exit 1
fi

# Check if pods are running
print_status "Checking pod status..."
PODS=$(kubectl get pods -n subgraphs-only -o jsonpath='{.items[*].status.phase}')
RUNNING_PODS=$(echo $PODS | grep -o "Running" | wc -l)
TOTAL_PODS=$(echo $PODS | wc -w)

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    print_success "All $TOTAL_PODS pods are running"
else
    print_error "Only $RUNNING_PODS/$TOTAL_PODS pods are running"
    kubectl get pods -n subgraphs-only
    exit 1
fi

echo ""
echo "=== METHOD 1: PORT FORWARDING ==="
print_status "Testing access via kubectl port-forward..."

# Start port-forward
kubectl port-forward svc/subgraphs-service 4001:4001 -n subgraphs-only &
PF_PID=$!

# Wait for port-forward to be ready
sleep 5

# Test health endpoint
if curl -s http://localhost:4001/health > /dev/null; then
    print_success "Health endpoint accessible via port-forward"
else
    print_error "Health endpoint not accessible via port-forward"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test GraphQL endpoints
print_status "Testing GraphQL endpoints via port-forward..."

# Test products
if curl -s -X POST http://localhost:4001/products/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title } }"}' | grep -q "data"; then
    print_success "Products subgraph working via port-forward"
else
    print_error "Products subgraph not working via port-forward"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test users
if curl -s -X POST http://localhost:4001/users/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ allUsers { id } }"}' | grep -q "data"; then
    print_success "Users subgraph working via port-forward"
else
    print_error "Users subgraph not working via port-forward"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Stop port-forward
kill $PF_PID 2>/dev/null || true

echo ""
echo "=== METHOD 2: MINIKUBE SERVICE ==="
print_status "Testing access via minikube service..."

print_warning "Note: minikube service requires an interactive terminal to create the tunnel"
print_status "To test external access via minikube service:"
echo "  1. Open a new terminal"
echo "  2. Run: minikube service subgraphs-service -n subgraphs-only"
echo "  3. This will open your browser to the service"
echo ""
print_status "Alternative: You can also run:"
echo "  minikube service subgraphs-service -n subgraphs-only --url"
echo "  (This will show the URL but requires keeping the terminal open)"

echo ""
echo "=== SUMMARY ==="
print_success "✅ Deployment validation completed!"
echo ""
echo "📋 Access Methods:"
echo ""
echo "🔧 Method 1: Port Forwarding (Recommended for development)"
echo "  kubectl port-forward svc/subgraphs-service 4001:4001 -n subgraphs-only"
echo "  Then access:"
echo "    - Health: http://localhost:4001/health"
echo "    - Products: http://localhost:4001/products/graphql"
echo "    - Users: http://localhost:4001/users/graphql"
echo ""
echo "🌐 Method 2: Minikube Service (For browser access)"
echo "  minikube service subgraphs-service -n subgraphs-only"
echo "  This will open your browser to the service"
echo ""
echo "🧪 Test Commands:"
echo "  # Health check"
echo "  curl http://localhost:4001/health"
echo ""
echo "  # Products query"
echo "  curl -X POST http://localhost:4001/products/graphql \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"query\":\"{ searchProducts { id title price } }\"}'"
echo ""
echo "  # Users query"
echo "  curl -X POST http://localhost:4001/users/graphql \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"query\":\"{ allUsers { id } }\"}'"
