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
    echo "  -d, --detailed        Show detailed resource information"
    echo "  -p, --pods            Show only pod status"
    echo "  -s, --services        Show only service status"
    echo "  -i, --ingress         Show only ingress status"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show basic status"
    echo "  $0 --detailed         # Show detailed information"
    echo "  $0 --pods             # Show only pod status"
    echo "  $0 --help             # Show this help message"
}

# Parse command line arguments
DETAILED=false
SHOW_PODS=false
SHOW_SERVICES=false
SHOW_INGRESS=false

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

show_script_header "Kubernetes Status" "Checking Apollo Supergraph resources in minikube"

# Check if minikube is running
if ! minikube_is_running; then
    print_error "Minikube is not running. Please start minikube first:"
    echo "  minikube start"
    echo "  or run: ./setup-minikube.sh"
    exit 1
fi

print_success "Minikube is running"

# Get minikube IP
MINIKUBE_IP=$(get_minikube_ip)
print_status "Minikube IP: $MINIKUBE_IP"

# Check if namespace exists
NAMESPACE="apollo-supergraph"
if ! namespace_exists "$NAMESPACE"; then
    print_warning "Namespace '$NAMESPACE' does not exist"
    echo "  Run: ./run-k8s.sh to deploy the supergraph"
    exit 1
fi

print_success "Namespace '$NAMESPACE' exists"

# Function to show pod status
show_pod_status() {
    print_status "Pod Status:"
    echo ""
    
    local pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null || true)
    
    if [ -z "$pods" ]; then
        print_warning "No pods found in namespace '$NAMESPACE'"
        return
    fi
    
    if [ "$DETAILED" = true ]; then
        kubectl get pods -n "$NAMESPACE" -o wide
    else
        kubectl get pods -n "$NAMESPACE"
    fi
    
    echo ""
    
    # Show pod logs summary
    print_status "Recent pod events:"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -5
}

# Function to show service status
show_service_status() {
    print_status "Service Status:"
    echo ""
    
    local services=$(kubectl get services -n "$NAMESPACE" --no-headers 2>/dev/null || true)
    
    if [ -z "$services" ]; then
        print_warning "No services found in namespace '$NAMESPACE'"
        return
    fi
    
    if [ "$DETAILED" = true ]; then
        kubectl get services -n "$NAMESPACE" -o wide
    else
        kubectl get services -n "$NAMESPACE"
    fi
    
    echo ""
    
    # Show service endpoints
    print_status "Service Endpoints:"
    kubectl get endpoints -n "$NAMESPACE"
}

# Function to show ingress status
show_ingress_status() {
    print_status "Ingress Status:"
    echo ""
    
    local ingress=$(kubectl get ingress -n "$NAMESPACE" --no-headers 2>/dev/null || true)
    
    if [ -z "$ingress" ]; then
        print_warning "No ingress found in namespace '$NAMESPACE'"
        return
    fi
    
    kubectl get ingress -n "$NAMESPACE"
    
    echo ""
    
    # Show ingress details
    if [ "$DETAILED" = true ]; then
        print_status "Ingress Details:"
        kubectl describe ingress -n "$NAMESPACE"
    fi
}

# Function to show deployment status
show_deployment_status() {
    print_status "Deployment Status:"
    echo ""
    
    local deployments=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null || true)
    
    if [ -z "$deployments" ]; then
        print_warning "No deployments found in namespace '$NAMESPACE'"
        return
    fi
    
    kubectl get deployments -n "$NAMESPACE"
    
    echo ""
    
    # Show deployment details
    if [ "$DETAILED" = true ]; then
        print_status "Deployment Details:"
        kubectl describe deployments -n "$NAMESPACE"
    fi
}

# Function to show resource usage
show_resource_usage() {
    print_status "Resource Usage:"
    echo ""
    
    # Show node resource usage
    print_status "Node Resources:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server not available"
    
    echo ""
    
    # Show pod resource usage
    print_status "Pod Resources:"
    kubectl top pods -n "$NAMESPACE" 2>/dev/null || print_warning "Metrics server not available"
}

# Function to show port forwarding status
show_port_forward_status() {
    print_status "Port Forwarding Status:"
    echo ""
    
    # Check if port 4000 is being forwarded
    if lsof -i :4000 > /dev/null 2>&1; then
        print_success "Port 4000 is being forwarded (router)"
        lsof -i :4000 | grep LISTEN
    else
        print_warning "Port 4000 is not being forwarded"
        echo "  Run: kubectl port-forward -n $NAMESPACE svc/router 4000:4000"
    fi
    
    echo ""
    
    # Check if port 4001 is being forwarded
    if lsof -i :4001 > /dev/null 2>&1; then
        print_success "Port 4001 is being forwarded (subgraphs)"
        lsof -i :4001 | grep LISTEN
    else
        print_warning "Port 4001 is not being forwarded"
        echo "  Run: kubectl port-forward -n $NAMESPACE svc/subgraphs 4001:4001"
    fi
}

# Function to show access URLs
show_access_urls() {
    print_status "Access URLs:"
    echo ""
    
    echo "  Router GraphQL:     http://localhost:4000/graphql"
    echo "  Router Health:      http://localhost:4000/health"
    echo "  Subgraphs:          http://localhost:4001"
    echo "  Minikube Dashboard: $(minikube dashboard --url 2>/dev/null || echo 'minikube dashboard')"
    echo ""
    
    if [ "$DETAILED" = true ]; then
        echo "  Test router:       ./test-router.sh"
        echo "  Test subgraphs:    curl http://localhost:4001/health"
    fi
}

# Main execution
if [ "$SHOW_PODS" = true ]; then
    show_pod_status
elif [ "$SHOW_SERVICES" = true ]; then
    show_service_status
elif [ "$SHOW_INGRESS" = true ]; then
    show_ingress_status
else
    # Show all status information
    show_pod_status
    echo ""
    show_service_status
    echo ""
    show_deployment_status
    echo ""
    show_ingress_status
    echo ""
    show_port_forward_status
    echo ""
    show_access_urls
    
    if [ "$DETAILED" = true ]; then
        echo ""
        show_resource_usage
    fi
fi

show_script_footer "Kubernetes Status"
