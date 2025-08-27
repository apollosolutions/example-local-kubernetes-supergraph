#!/bin/bash

set -e

echo "🧪 Testing subgraphs-only deployment..."

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

# Check if service is ready
print_status "Checking service status..."
kubectl get svc -n subgraphs-only

# Get minikube IP
MINIKUBE_IP=$(minikube ip)

# Test subgraphs health via minikube service
print_status "Testing subgraphs health via minikube service..."
SERVICE_URL=$(minikube service subgraphs-service -n subgraphs-only --url)
if [ $? -eq 0 ]; then
    print_success "Got service URL: $SERVICE_URL"
    if curl -s $SERVICE_URL/health > /dev/null; then
        print_success "Subgraphs are responding via minikube service"
    else
        print_error "Subgraphs are not responding via minikube service"
        exit 1
    fi
else
    print_error "Failed to get service URL"
    exit 1
fi

# Test GraphQL query to subgraphs via minikube service
print_status "Testing GraphQL query to subgraphs via minikube service..."
RESPONSE=$(curl -s -X POST $SERVICE_URL/products/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title price } }"}')

if echo "$RESPONSE" | grep -q "data"; then
    print_success "GraphQL query to subgraphs successful"
    echo "Response: $RESPONSE" | head -c 200
    echo "..."
else
    print_error "GraphQL query to subgraphs failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test all three subgraph endpoints
print_status "Testing all subgraph endpoints..."

# Test products
if curl -s -X POST $SERVICE_URL/products/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title } }"}' | grep -q "data"; then
    print_success "Products subgraph is working"
else
    print_error "Products subgraph is not working"
    exit 1
fi

# Test reviews
if curl -s -X POST $SERVICE_URL/reviews/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ reviews { id text rating } }"}' | grep -q "data"; then
    print_success "Reviews subgraph is working"
else
    print_error "Reviews subgraph is not working"
    exit 1
fi

# Test users
if curl -s -X POST $SERVICE_URL/users/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ users { id name email } }"}' | grep -q "data"; then
    print_success "Users subgraph is working"
else
    print_error "Users subgraph is not working"
    exit 1
fi

print_success "All tests passed! 🎉"
echo ""
echo "📋 Test Summary:"
echo "  ✅ All pods are running"
echo "  ✅ Service is configured"
echo "  ✅ NodePort access is working"
echo "  ✅ All three subgraphs are responding"
echo "  ✅ GraphQL queries work"
echo ""
echo "🌐 Your subgraphs are accessible from your browser:"
echo "  - Use: minikube service subgraphs-service -n subgraphs-only"
echo "  - Or access via: $SERVICE_URL"
echo "  - Products: $SERVICE_URL/products/graphql"
echo "  - Reviews: $SERVICE_URL/reviews/graphql"
echo "  - Users: $SERVICE_URL/users/graphql"
echo ""
echo "💡 You can also use port-forward for localhost access:"
echo "  kubectl port-forward svc/subgraphs-service 4001:4001 -n subgraphs-only"
