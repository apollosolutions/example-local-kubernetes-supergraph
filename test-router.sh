#!/bin/bash

set -e

# Source shared utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# If SCRIPT_DIR is the root directory, we need to source from scripts subdirectory
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
    source "$SCRIPT_DIR/utils.sh"
    source "$SCRIPT_DIR/test-utils.sh"
    source "$SCRIPT_DIR/port-forward-utils.sh"
else
    source "$SCRIPT_DIR/scripts/utils.sh"
    source "$SCRIPT_DIR/scripts/test-utils.sh"
    source "$SCRIPT_DIR/scripts/port-forward-utils.sh"
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_NAME]"
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Test Names:"
    echo "  basic                 Test basic infrastructure (scripts, health)"
    echo "  health                Test router health endpoint"
    echo "  introspection         Test GraphQL introspection"
    echo "  queries               Test available queries"
    echo "  products              Test searchProducts query"
    echo "  product-schema        Test product schema"
    echo "  user                  Test user query"
    echo "  users                 Test allUsers query"
    echo "  port                  Test if port 4000 is listening"
    echo "  status                Show router status"
    echo "  all (default)         Run all tests"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 basic              # Test basic infrastructure"
    echo "  $0 products           # Test only searchProducts query"
    echo "  $0 status             # Show router status"
    echo "  $0 --help             # Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            TEST_NAME="$1"
            shift
            ;;
    esac
done

show_script_header "Apollo Router Testing" "Testing Apollo Router functionality"

# Check if minikube is running
if ! minikube_is_running; then
    print_error "Minikube is not running. Please start minikube first:"
    echo "  minikube start"
    echo "  or run: ./setup-minikube.sh"
    exit 1
fi

print_success "Minikube is running"

# Check and setup port forwarding if needed
print_status "Checking port forwarding..."
if ! is_port_forward_running "apollo-router"; then
    print_status "Port forwarding not running. Setting up automatically..."
    if start_router_port_forward; then
        print_success "Port forwarding setup complete"
    else
        print_error "Failed to setup port forwarding. Please run manually:"
        echo "  source scripts/port-forward-utils.sh && start_router_port_forward"
        exit 1
    fi
else
    print_success "Port forwarding already running"
fi

# Run the specified test or all tests
if [ -n "$TEST_NAME" ]; then
    run_test "$TEST_NAME"
else
    run_test "all"
fi

show_script_footer "Apollo Router Testing"
