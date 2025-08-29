#!/bin/bash

# =============================================================================
# Apollo Supergraph - Port Forwarding Utilities
# =============================================================================
#
# This script manages port forwarding for the Apollo Router and subgraphs
# in Kubernetes deployments.
#
# =============================================================================

# Source shared utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$SCRIPT_DIR/scripts/utils.sh"
source "$SCRIPT_DIR/scripts/config.sh"

# Configuration (now from config)
NAMESPACE=$(get_k8s_namespace)
PID_FILE_DIR="/tmp/apollo-supergraph"

# Create PID file directory if it doesn't exist
ensure_pid_dir() {
    ensure_directory "$PID_FILE_DIR"
}

# Get PID file path for a service
get_pid_file() {
    local service="$1"
    echo "$PID_FILE_DIR/${service}-port-forward.pid"
}

# Check if port forwarding is already running for a service
is_port_forward_running() {
    local service="$1"
    local pid_file=$(get_pid_file "$service")
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # Running
        else
            # PID file exists but process is dead, clean it up
            rm -f "$pid_file"
        fi
    fi
    return 1  # Not running
}

# Start port forwarding for a service
start_port_forward() {
    local service="$1"
    local port="$2"
    local pid_file=$(get_pid_file "$service")
    
    ensure_pid_dir
    
    # Check if already running
    if is_port_forward_running "$service"; then
        local pid=$(cat "$pid_file")
        print_warning "Port forwarding for $service is already running (PID: $pid)"
        return 0
    fi
    
    # Check if service exists
    if ! kubectl get svc "${service}-service" -n "$NAMESPACE" > /dev/null 2>&1; then
        print_error "Service ${service}-service not found in namespace $NAMESPACE"
        return 1
    fi
    
    # Start port forwarding
    print_status "Starting port forwarding for $service on port $port..."
    kubectl port-forward "svc/${service}-service" "$port:$port" -n "$NAMESPACE" > /dev/null 2>&1 &
    local pid=$!
    
    # Save PID
    echo "$pid" > "$pid_file"
    
    # Wait a moment for port forward to establish
    sleep 2
    
    # Verify it's working
    if kill -0 "$pid" 2>/dev/null; then
        print_success "Port forwarding for $service started (PID: $pid)"
        return 0
    else
        print_error "Failed to start port forwarding for $service"
        rm -f "$pid_file"
        return 1
    fi
}

# Stop port forwarding for a service
stop_port_forward() {
    local service="$1"
    local pid_file=$(get_pid_file "$service")
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Stopping port forwarding for $service (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 1
            if ! kill -0 "$pid" 2>/dev/null; then
                print_success "Port forwarding for $service stopped"
            else
                print_warning "Port forwarding for $service may still be running"
            fi
        fi
        rm -f "$pid_file"
    else
        print_warning "No port forwarding found for $service"
    fi
}

# Stop all port forwarding
stop_all_port_forward() {
    print_status "Stopping all port forwarding..."
    stop_port_forward "apollo-router"
    stop_port_forward "subgraphs"
    print_success "All port forwarding stopped"
}

# Check if a port is listening
is_port_listening() {
    local port="$1"
    lsof -i ":$port" > /dev/null 2>&1
}

# Wait for port forwarding to be ready
wait_for_port_forward() {
    local service="$1"
    local port="$2"
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service port forwarding to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if is_port_listening "$port"; then
            print_success "$service port forwarding is ready"
            return 0
        fi
        
        sleep 1
        attempt=$((attempt + 1))
    done
    
    print_error "$service port forwarding failed to become ready after $max_attempts seconds"
    return 1
}

# Start router port forwarding
start_router_port_forward() {
    start_port_forward "apollo-router" "$ROUTER_GRAPHQL_PORT"
    if [ $? -eq 0 ]; then
        wait_for_port_forward "apollo-router" "$ROUTER_GRAPHQL_PORT"
    fi
}

# Start subgraphs port forwarding
start_subgraphs_port_forward() {
    start_port_forward "subgraphs" "$SUBGRAPHS_PORT"
    if [ $? -eq 0 ]; then
        wait_for_port_forward "subgraphs" "$SUBGRAPHS_PORT"
    fi
}

# Start all port forwarding
start_all_port_forward() {
    print_status "Starting all port forwarding..."
    start_router_port_forward
    start_subgraphs_port_forward
    print_success "All port forwarding started"
}

# Show port forwarding status
show_port_forward_status() {
    print_status "Port Forwarding Status:"
    echo ""
    
    # Check router
    if is_port_forward_running "apollo-router"; then
        local pid=$(cat $(get_pid_file "apollo-router"))
        print_success "Router: Running (PID: $pid) - http://localhost:$ROUTER_GRAPHQL_PORT"
    else
        print_error "Router: Not running"
    fi
    
    # Check subgraphs
    if is_port_forward_running "subgraphs"; then
        local pid=$(cat $(get_pid_file "subgraphs"))
        print_success "Subgraphs: Running (PID: $pid) - http://localhost:$SUBGRAPHS_PORT"
    else
        print_error "Subgraphs: Not running"
    fi
    
    echo ""
    print_status "Useful commands:"
    echo "  - Start all: source scripts/port-forward-utils.sh && start_all_port_forward"
    echo "  - Stop all: source scripts/port-forward-utils.sh && stop_all_port_forward"
    echo "  - Status: source scripts/port-forward-utils.sh && show_port_forward_status"
}

# Cleanup function for script exit
cleanup_on_exit() {
    # Only cleanup if this script is being run directly
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        stop_all_port_forward
    fi
}

# Set trap for cleanup
trap cleanup_on_exit EXIT

# If script is run directly, show status
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        show_port_forward_status
    else
        case "$1" in
            "start")
                start_all_port_forward
                ;;
            "stop")
                stop_all_port_forward
                ;;
            "status")
                show_port_forward_status
                ;;
            "router")
                start_router_port_forward
                ;;
            "subgraphs")
                start_subgraphs_port_forward
                ;;
            *)
                echo "Usage: $0 [start|stop|status|router|subgraphs]"
                echo ""
                echo "Commands:"
                echo "  start     - Start all port forwarding"
                echo "  stop      - Stop all port forwarding"
                echo "  status    - Show port forwarding status"
                echo "  router    - Start router port forwarding only"
                echo "  subgraphs - Start subgraphs port forwarding only"
                exit 1
                ;;
        esac
    fi
fi
