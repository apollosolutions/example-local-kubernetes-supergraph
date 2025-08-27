#!/bin/bash

# =============================================================================
# Apollo Supergraph - Local Test Script
# =============================================================================
#
# This script runs local tests to verify the Apollo Supergraph setup
# without requiring minikube or Kubernetes.
#
# =============================================================================

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

show_script_header "Local Testing" "Testing Apollo Supergraph components locally"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --all              Run all tests (default)"
    echo "  -s, --subgraphs        Test subgraphs only"
    echo "  -c, --composition      Test supergraph composition only"
    echo "  -d, --docker           Test Docker builds only"
    echo "  -r, --router           Test router only"
    echo "  -y, --yaml             Test YAML formatting only"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Run all tests"
    echo "  $0 --subgraphs         # Test subgraphs only"
    echo "  $0 --composition       # Test composition only"
    echo "  $0 --yaml              # Test YAML formatting only"
}

# Default values
TEST_SUBGRAPHS=true
TEST_COMPOSITION=true
TEST_DOCKER=true
TEST_ROUTER=true
TEST_YAML=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            TEST_SUBGRAPHS=true
            TEST_COMPOSITION=true
            TEST_DOCKER=true
            TEST_ROUTER=true
            TEST_YAML=true
            shift
            ;;
        -s|--subgraphs)
            TEST_SUBGRAPHS=true
            TEST_COMPOSITION=false
            TEST_DOCKER=false
            TEST_ROUTER=false
            TEST_YAML=false
            shift
            ;;
        -c|--composition)
            TEST_SUBGRAPHS=false
            TEST_COMPOSITION=true
            TEST_DOCKER=false
            TEST_ROUTER=false
            TEST_YAML=false
            shift
            ;;
        -d|--docker)
            TEST_SUBGRAPHS=false
            TEST_COMPOSITION=false
            TEST_DOCKER=true
            TEST_ROUTER=false
            TEST_YAML=false
            shift
            ;;
        -r|--router)
            TEST_SUBGRAPHS=false
            TEST_COMPOSITION=false
            TEST_DOCKER=false
            TEST_ROUTER=true
            TEST_YAML=false
            shift
            ;;
        -y|--yaml)
            TEST_SUBGRAPHS=false
            TEST_COMPOSITION=false
            TEST_DOCKER=false
            TEST_ROUTER=false
            TEST_YAML=true
            shift
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

# Validate required tools
if ! validate_required_tools; then
    exit 1
fi

# Test subgraphs
if [ "$TEST_SUBGRAPHS" = true ]; then
    print_status "Testing subgraphs..."
    
    if ! file_exists "subgraphs/package.json"; then
        print_error "subgraphs/package.json not found"
        exit 1
    fi
    
    cd subgraphs
    
    # Install dependencies
    print_status "Installing dependencies..."
    npm ci
    
    # Test build if available
    if npm run | grep -q "build"; then
        print_status "Testing build..."
        npm run build
    else
        print_warning "No build script found, skipping"
    fi
    
    # Test lint if available
    if npm run | grep -q "lint"; then
        print_status "Testing lint..."
        npm run lint
    else
        print_warning "No lint script found, skipping"
    fi
    
    # Test validation if available
    if npm run | grep -q "validate"; then
        print_status "Testing validation..."
        npm run validate
    else
        print_warning "No validate script found, skipping"
    fi
    
    cd ..
    print_success "Subgraphs tests passed"
fi

# Test supergraph composition
if [ "$TEST_COMPOSITION" = true ]; then
    print_status "Testing supergraph composition..."
    
    if ! file_exists "router/compose.sh"; then
        print_error "router/compose.sh not found"
        exit 1
    fi
    
    cd router
    
    # Check if Rover is available
    if ! command_exists rover; then
        print_warning "Rover CLI not found, installing..."
        curl -sSL https://rover.apollo.dev/nix/latest | sh
        export PATH="$HOME/.rover/bin:$PATH"
    fi
    
    # Run composition
    ./compose.sh
    
    # Verify the supergraph file was created
    if [ ! -f "supergraph.graphql" ]; then
        print_error "Supergraph composition failed - supergraph.graphql not created"
        exit 1
    fi
    
    # Verify the supergraph contains expected content
    if ! grep -q "join__Graph" supergraph.graphql; then
        print_error "Supergraph composition failed - missing join__Graph"
        exit 1
    fi
    
    cd ..
    print_success "Supergraph composition test passed"
fi

# Test Docker builds
if [ "$TEST_DOCKER" = true ]; then
    print_status "Testing Docker builds..."
    
    if ! file_exists "subgraphs/Dockerfile"; then
        print_error "subgraphs/Dockerfile not found"
        exit 1
    fi
    
    cd subgraphs
    
    # Build Docker image
    docker build -t subgraphs:test .
    
    # Verify the image was created
    if ! docker images | grep -q "subgraphs.*test"; then
        print_error "Docker build failed for subgraphs"
        exit 1
    fi
    
    cd ..
    print_success "Docker build test passed"
fi

# Test YAML formatting
if [ "$TEST_YAML" = true ]; then
    print_status "Testing YAML formatting..."
    
    # Check if yamllint is available
    if ! command_exists yamllint; then
        print_warning "yamllint not found, installing..."
        if command_exists pip3; then
            pip3 install yamllint
        elif command_exists pip; then
            pip install yamllint
        else
            print_error "pip not found, cannot install yamllint"
            exit 1
        fi
    fi
    
    # Test all YAML files in k8s directory
    if [ -d "k8s" ]; then
        print_status "Linting Kubernetes manifests..."
        yamllint k8s/ || {
            print_error "YAML linting failed"
            exit 1
        }
        print_success "Kubernetes manifests YAML linting passed"
    else
        print_warning "k8s directory not found, skipping YAML linting"
    fi
    
    # Test router configuration YAML
    if file_exists "router/router.yaml"; then
        print_status "Linting router configuration..."
        yamllint router/router.yaml || {
            print_error "Router configuration YAML linting failed"
            exit 1
        }
        print_success "Router configuration YAML linting passed"
    else
        print_warning "router/router.yaml not found, skipping"
    fi
    
    print_success "YAML formatting test passed"
fi

# Test router and subgraphs functionality
if [ "$TEST_ROUTER" = true ]; then
    print_status "Testing router and subgraphs functionality..."
    
    # Start subgraphs container
    print_status "Starting subgraphs container..."
    docker run -d --name subgraphs-test -p 4001:4001 subgraphs:test
    
    # Wait for container to start
    sleep 10
    
    # Check if container is running
    if ! docker ps | grep -q "subgraphs-test"; then
        print_error "Subgraphs container failed to start"
        docker logs subgraphs-test
        exit 1
    fi
    
    # Test subgraphs endpoints
    print_status "Testing subgraphs endpoints..."
    
    # Test products endpoint
    curl -X POST http://localhost:4001/products/graphql \
      -H "Content-Type: application/json" \
      -d '{"query":"{ searchProducts { id title price } }"}' \
      --max-time 10 \
      --retry 3 \
      --retry-delay 2 > /dev/null || {
        print_error "Products endpoint test failed"
        docker logs subgraphs-test
        exit 1
    }
    
    # Test reviews endpoint
    curl -X POST http://localhost:4001/reviews/graphql \
      -H "Content-Type: application/json" \
      -d '{"query":"{ __typename }"}' \
      --max-time 10 \
      --retry 3 \
      --retry-delay 2 > /dev/null || {
        print_error "Reviews endpoint test failed"
        docker logs subgraphs-test
        exit 1
    }
    
    # Test users endpoint
    curl -X POST http://localhost:4001/users/graphql \
      -H "Content-Type: application/json" \
      -d '{"query":"{ allUsers { id username } }"}' \
      --max-time 10 \
      --retry 3 \
      --retry-delay 2 > /dev/null || {
        print_error "Users endpoint test failed"
        docker logs subgraphs-test
        exit 1
    }
    
    print_success "Subgraphs endpoints test passed"
    
    # Test router
    print_status "Testing router..."
    
    # Create a test supergraph with localhost URLs
    cd router
    ./compose.sh
    
    # Start router with test supergraph
    docker run -d --name router-test \
      -p 4000:4000 \
      -v $(pwd)/supergraph.graphql:/dist/supergraph.graphql \
      -v $(pwd)/router.yaml:/dist/config.yaml \
      ghcr.io/apollographql/router:v2.5.0 \
      --config /dist/config.yaml \
      --supergraph /dist/supergraph.graphql
    
    # Wait for router to start
    sleep 15
    
    # Test router endpoint
    curl -X POST http://localhost:4000/graphql \
      -H "Content-Type: application/json" \
      -d '{"query":"{ searchProducts { id title price } }"}' \
      --max-time 10 \
      --retry 3 \
      --retry-delay 2 > /dev/null || {
        print_error "Router endpoint test failed"
        docker logs router-test
        exit 1
    }
    
    cd ..
    print_success "Router test passed"
    
    # Cleanup containers
    print_status "Cleaning up test containers..."
    docker stop router-test subgraphs-test || true
    docker rm router-test subgraphs-test || true
fi

print_success "All local tests passed!"
echo ""
echo "📋 Test Summary:"
if [ "$TEST_SUBGRAPHS" = true ]; then
    echo "  ✅ Subgraphs tests"
fi
if [ "$TEST_COMPOSITION" = true ]; then
    echo "  ✅ Supergraph composition"
fi
if [ "$TEST_DOCKER" = true ]; then
    echo "  ✅ Docker builds"
fi
if [ "$TEST_YAML" = true ]; then
    echo "  ✅ YAML formatting"
fi
if [ "$TEST_ROUTER" = true ]; then
    echo "  ✅ Router and subgraphs functionality"
fi

show_script_footer "Local Testing"
