#!/bin/bash

# =============================================================================
# Apollo Supergraph - Local Development Script (No Kubernetes)
# =============================================================================
#
# This script runs the Apollo Supergraph locally WITHOUT Kubernetes:
# - Subgraphs: Runs directly with npm start (Node.js)
# - Router: Runs directly with rover dev (Apollo Router)
#
# This is different from the Kubernetes deployment which runs everything
# in containers within minikube. This approach is faster and simpler
# for development.
#
# Usage:
#   ./run-local.sh              # Run both subgraphs and router
#   ./run-local.sh --subgraphs-only   # Run only subgraphs
#   ./run-local.sh --router-only      # Run only router
#
# =============================================================================

set -e

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message"
    echo "  -s, --subgraphs-only  Run only the subgraphs (for development)"
    echo "  -r, --router-only     Run only the router (requires subgraphs running)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run both subgraphs and router"
    echo "  $0 --subgraphs-only   # Run only subgraphs"
    echo "  $0 --router-only      # Run only router"
    echo "  $0 --help             # Show this help message"
}

# Parse command line arguments
RUN_SUBGRAPHS=true
RUN_ROUTER=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subgraphs-only)
            RUN_SUBGRAPHS=true
            RUN_ROUTER=false
            shift
            ;;
        -r|--router-only)
            RUN_SUBGRAPHS=false
            RUN_ROUTER=true
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

echo "🚀 Starting Apollo Supergraph locally..."

# Check if .env file exists
if [ ! -f "router/.env" ]; then
    print_error "router/.env file not found. Please create it with APOLLO_KEY and APOLLO_GRAPH_REF"
    print_error "Run the following command to create it safely:"
    print_error "  if [ ! -f \"router/.env\" ]; then cp router/env.example router/.env; fi"
    print_error "Then edit router/.env with your actual Apollo Studio credentials"
    exit 1
fi

# Install/update Rover if needed
print_status "Checking Rover installation..."
if ! command -v rover &> /dev/null; then
    print_status "Rover not found. Installing Rover..."
    cd router
    ./download-rover.sh
    cd ..
else
    print_success "Rover is already installed"
fi

# Generate supergraph schema
print_status "Generating supergraph schema..."
cd router
./compose.sh
cd ..
print_success "Supergraph schema generated"

# Function to cleanup background processes
cleanup() {
    print_status "Cleaning up background processes..."
    pkill -f "npm start" || true
    pkill -f "rover dev" || true
    print_success "Cleanup completed"
}

# Set up trap to cleanup on script exit
trap cleanup EXIT

# Run subgraphs if requested
if [ "$RUN_SUBGRAPHS" = true ]; then
    print_status "Starting subgraphs..."
    cd subgraphs
    npm start &
    SUBGRAPHS_PID=$!
    cd ..
    
    # Wait for subgraphs to be ready
    print_status "Waiting for subgraphs to be ready..."
    sleep 5
    
    # Test if subgraphs are responding
    for i in {1..15}; do
        if curl -s http://localhost:4001/products/graphql > /dev/null 2>&1 && \
           curl -s http://localhost:4001/reviews/graphql > /dev/null 2>&1 && \
           curl -s http://localhost:4001/users/graphql > /dev/null 2>&1; then
            print_success "Subgraphs are ready!"
            break
        fi
        if [ $i -eq 15 ]; then
            print_error "Subgraphs failed to start properly"
            exit 1
        fi
        print_status "Waiting for subgraphs... (attempt $i/15)"
        sleep 3
    done
    
    # Regenerate supergraph schema after subgraphs are ready
    print_status "Regenerating supergraph schema..."
    cd router
    ./compose.sh
    cd ..
    print_success "Supergraph schema regenerated"
fi

# Run router if requested
if [ "$RUN_ROUTER" = true ]; then
    # Check if subgraphs are running when using router-only mode
    if [ "$RUN_SUBGRAPHS" = false ]; then
        print_status "Checking if subgraphs are running..."
        if ! curl -s http://localhost:4001/products/graphql > /dev/null 2>&1; then
            print_error "Subgraphs are not running on localhost:4001"
            print_error "Please start the subgraphs first:"
            print_error "  ./run-local.sh --subgraphs-only"
            print_error "  or"
            print_error "  ./run-local.sh"
            exit 1
        fi
        print_success "Subgraphs are running"
    fi
    
    print_status "Starting Apollo Router..."
    cd router
    ./rover-dev.sh &
    ROUTER_PID=$!
    cd ..
    
    # Wait for router to be ready
    print_status "Waiting for Apollo Router to be ready..."
    sleep 5
    
    # Test if router is responding
    for i in {1..10}; do
        if curl -s http://localhost:8088/health > /dev/null 2>&1; then
            print_success "Apollo Router is ready!"
            break
        fi
        if [ $i -eq 10 ]; then
            print_error "Apollo Router failed to start properly"
            print_error "Check router logs for more details"
            exit 1
        fi
        print_status "Waiting for router... (attempt $i/10)"
        sleep 2
    done
fi

print_success "Apollo Supergraph is running locally!"
echo ""
echo "📋 Service Status:"

if [ "$RUN_SUBGRAPHS" = true ]; then
    echo "  ✅ Subgraphs: http://localhost:4001"
    echo "    - Products: http://localhost:4001/products/graphql"
    echo "    - Reviews: http://localhost:4001/reviews/graphql"
    echo "    - Users: http://localhost:4001/users/graphql"
fi

if [ "$RUN_ROUTER" = true ]; then
    echo "  ✅ Apollo Router: http://localhost:4000/graphql"
    echo "  ✅ Router Health: http://localhost:8088/health"
fi

echo ""
echo "🧪 Test the GraphQL API:"
echo "  curl -X POST http://localhost:4000/graphql \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"query\":\"{ searchProducts { id title price } }\"}'"
echo ""
echo "🔍 Useful commands:"
echo "  - View subgraphs logs: tail -f subgraphs/logs/*"
echo "  - View router logs: Check the terminal where rover-dev.sh is running"
echo "  - Stop all services: Ctrl+C (this script will cleanup automatically)"
echo ""
echo "⚠️  Press Ctrl+C to stop all services"

# Keep the script running and wait for background processes
wait
