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
    echo "  -r, --replicas NUM    Number of replicas for router and subgraphs (default: 2)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy Apollo Supergraph with 2 replicas (default)"
    echo "  $0 --replicas 3       # Deploy Apollo Supergraph with 3 replicas"
    echo "  $0 -r 1               # Deploy Apollo Supergraph with 1 replica"
    echo "  $0 --help             # Show this help message"
}

# Default values
NAMESPACE="apollo-supergraph"
SERVICE_TYPE="ClusterIP"
REPLICAS=2

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--replicas)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                REPLICAS="$2"
                shift 2
            else
                print_error "Replicas must be a positive integer"
                show_usage
                exit 1
            fi
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

show_script_header "Apollo Supergraph Kubernetes Deployment" "Deploying Apollo Supergraph (router + subgraphs) to minikube"

# Validate required tools
if ! validate_required_tools; then
    exit 1
fi

# Check if minikube is running
if ! minikube_is_running; then
    print_error "Minikube is not running. Please start minikube first:"
    echo "  minikube start"
    echo "  or run: ./setup-minikube.sh"
    exit 1
fi

print_success "Minikube is running"

# Source environment variables from .env file
if file_exists "router/.env"; then
    print_status "Loading environment variables from router/.env"
    # Load environment variables from .env file (simple key=value format)
    set -a  # automatically export all variables
    source router/.env
    set +a  # stop automatically exporting
else
    print_error "router/.env file not found. Please create it with APOLLO_KEY and APOLLO_GRAPH_REF"
    print_error "Run the following command to create it safely:"
    print_error "  ./setup-env.sh"
    print_error "Then edit router/.env with your actual Apollo Studio credentials"
    exit 1
fi

# Verify required environment variables are set
if [ -z "$APOLLO_KEY" ] || [ -z "$APOLLO_GRAPH_REF" ]; then
    print_error "APOLLO_KEY and APOLLO_GRAPH_REF must be set in router/.env"
    print_error "Make sure your .env file contains simple key=value pairs (no export statements)"
    exit 1
fi

print_status "Using APOLLO_GRAPH_REF: $APOLLO_GRAPH_REF"

# Build subgraphs Docker image
# Check if Docker is available in minikube
if ! minikube docker-env > /dev/null 2>&1; then
    print_error "Cannot get minikube Docker environment"
    exit 1
fi

# Set Docker environment to use minikube's Docker daemon
eval $(minikube docker-env)

print_status "Building subgraphs Docker image..."
cd subgraphs
docker build -t subgraphs:latest .
cd ..
print_success "Subgraphs Docker image built successfully"

# Create namespace
print_status "Creating namespace: $NAMESPACE"
kubectl apply -f k8s/namespace.yaml

# Set deployment environment variables
export NAMESPACE
export SERVICE_TYPE
export ROUTER_REPLICAS=$REPLICAS
export SUBGRAPHS_REPLICAS=$REPLICAS

# Create ConfigMaps from router files (single source of truth)
print_status "Creating ConfigMaps from router files..."

# Create router-config ConfigMap from router/router.yaml
kubectl create configmap router-config \
  --from-file=config.yaml=router/router.yaml \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# Generate supergraph with Kubernetes URLs and create ConfigMap
print_status "Generating supergraph with Kubernetes URLs..."
cd router
# Generate supergraph with localhost URLs first
./compose.sh
# Create a temporary copy with Kubernetes URLs
sed 's|http://localhost:4001|http://subgraphs-service.apollo-supergraph.svc.cluster.local:4001|g' supergraph.graphql > supergraph-k8s.graphql
cd ..

# Create supergraph-schema ConfigMap from the Kubernetes version
kubectl create configmap supergraph-schema \
  --from-file=supergraph.graphql=router/supergraph-k8s.graphql \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up temporary file
rm router/supergraph-k8s.graphql

# Deploy subgraphs
print_status "Deploying subgraphs..."
NAMESPACE=$NAMESPACE SUBGRAPHS_REPLICAS=$SUBGRAPHS_REPLICAS envsubst < k8s/subgraphs-deployment-clusterip.yaml | kubectl apply -f -

# Wait for subgraphs to be ready
wait_for_deployment "subgraphs" "$NAMESPACE"

# Deploy Apollo Router
print_status "Deploying Apollo Router..."
NAMESPACE=$NAMESPACE ROUTER_REPLICAS=$ROUTER_REPLICAS APOLLO_GRAPH_REF=$APOLLO_GRAPH_REF APOLLO_KEY=$APOLLO_KEY envsubst < k8s/router-deployment-clusterip.yaml | kubectl apply -f -

# Wait for router to be ready
wait_for_deployment "apollo-router" "$NAMESPACE"

# Apply Ingress
print_status "Applying Ingress configuration..."
kubectl apply -f k8s/ingress.yaml

# Wait for ingress to be ready
print_status "Waiting for Ingress to be ready..."
sleep 10

# Get minikube IP
MINIKUBE_IP=$(get_minikube_ip)

print_success "Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  - Namespace: $NAMESPACE"
echo "  - Service Type: $SERVICE_TYPE"
echo "  - Subgraphs: ${SUBGRAPHS_REPLICAS} replica(s)"
echo "  - Apollo Router: ${ROUTER_REPLICAS} replica(s)"

echo ""
echo "🌐 Access your applications:"
echo "  - Apollo Router: http://apollo-router.local (add to /etc/hosts: $MINIKUBE_IP apollo-router.local)"
echo "  - Router Health: http://$MINIKUBE_IP:$(kubectl get svc apollo-router-service -n $NAMESPACE -o jsonpath='{.spec.ports[?(@.name=="health")].nodePort}')"
echo ""
print_warning "Don't forget to add the following line to your /etc/hosts file:"
echo "  $MINIKUBE_IP apollo-router.local"

echo ""
echo "🔍 Useful commands:"
echo "  - View pods: kubectl get pods -n $NAMESPACE"
echo "  - View services: kubectl get svc -n $NAMESPACE"
echo "  - View router logs: kubectl logs -f deployment/apollo-router -n $NAMESPACE"
echo "  - Port forward router: kubectl port-forward svc/apollo-router-service 4000:4000 -n $NAMESPACE"
echo "  - View subgraphs logs: kubectl logs -f deployment/subgraphs -n $NAMESPACE"
echo "  - Port forward subgraphs: kubectl port-forward svc/subgraphs-service 4001:4001 -n $NAMESPACE"

show_script_footer "Apollo Supergraph Deployment"
