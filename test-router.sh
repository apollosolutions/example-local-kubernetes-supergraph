#!/bin/bash

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"
source "$SCRIPT_DIR/scripts/test-utils.sh"

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

# Run the specified test or all tests
if [ -n "$TEST_NAME" ]; then
    run_test "$TEST_NAME"
else
    run_test "all"
fi

show_script_footer "Apollo Router Testing"
