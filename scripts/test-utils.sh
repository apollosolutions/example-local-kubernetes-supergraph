#!/bin/bash

# =============================================================================
# Apollo Supergraph - Test Utilities
# =============================================================================
#
# This script contains common test operations and curl commands used across
# multiple scripts for testing the Apollo Router and subgraphs.
#
# =============================================================================

# Source shared utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Default values (now from config)
ROUTER_URL=$(get_router_graphql_url | sed 's|/graphql$||')
HEALTH_ENDPOINT=$(get_router_health_url)
GRAPHQL_ENDPOINT=$(get_router_graphql_url)

# Function to test if port forwarding is working
test_port_forward() {
    local url="$1"
    local description="$2"
    
    if curl -s "$url" > /dev/null 2>&1; then
        print_success "$description is accessible"
        return 0
    else
        print_error "$description is not accessible"
        return 1
    fi
}

# Function to test router health endpoint
test_router_health() {
    print_status "Testing router health endpoint..."
    test_port_forward "$HEALTH_ENDPOINT" "Router health endpoint"
}

# Function to test GraphQL introspection
test_graphql_introspection() {
    print_status "Testing GraphQL introspection..."
    
    local response=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ __schema { types { name } } }"}')
    
    if echo "$response" | grep -q '"data"' && echo "$response" | grep -q '"__schema"'; then
        print_success "GraphQL introspection working"
        return 0
    else
        print_error "GraphQL introspection failed"
        return 1
    fi
}

# Function to test available queries
test_available_queries() {
    print_status "Testing available queries..."
    
    local response=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ __schema { queryType { fields { name } } } }"}')
    
    if echo "$response" | grep -q '"data"'; then
        print_success "Available queries retrieved"
        echo "$response" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g'
        return 0
    else
        print_error "Failed to retrieve available queries"
        return 1
    fi
}

# Function to test searchProducts query
test_search_products() {
    print_status "Testing searchProducts query..."
    
    local response=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ searchProducts { id title price } }"}')
    
    if echo "$response" | grep -q '"data"' && echo "$response" | grep -q '"searchProducts"'; then
        print_success "searchProducts query working"
        # Show first few products
        echo "$response" | grep -o '"title":"[^"]*"' | head -3 | sed 's/"title":"//g' | sed 's/"//g'
        return 0
    else
        print_error "searchProducts query failed"
        return 1
    fi
}

# Function to test product details
test_product_details() {
    print_status "Testing product details query..."
    
    local response=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ __type(name: \"Product\") { fields { name } } }"}')
    
    if echo "$response" | grep -q '"data"' && echo "$response" | grep -q '"fields"'; then
        print_success "Product schema retrieved"
        echo "$response" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g'
        return 0
    else
        print_error "Failed to retrieve product schema"
        return 1
    fi
}

# Function to test user query
test_user_query() {
    print_status "Testing user query..."
    
    local response=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ user(id: \"user:1\") { id username } }"}')
    
    if echo "$response" | grep -q '"data"' && echo "$response" | grep -q '"user"'; then
        print_success "User query working"
        return 0
    else
        print_error "User query failed"
        return 1
    fi
}

# Function to test all users query
test_all_users() {
    print_status "Testing allUsers query..."
    
    local response=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ allUsers { id username } }"}')
    
    if echo "$response" | grep -q '"data"' && echo "$response" | grep -q '"allUsers"'; then
        print_success "allUsers query working"
        return 0
    else
        print_error "allUsers query failed"
        return 1
    fi
}

# Function to run comprehensive router test
test_router_comprehensive() {
    print_status "Running comprehensive router tests..."
    echo ""
    
    local all_passed=true
    
    # Test health endpoint
    if ! test_router_health; then
        all_passed=false
    fi
    echo ""
    
    # Test GraphQL introspection
    if ! test_graphql_introspection; then
        all_passed=false
    fi
    echo ""
    
    # Test available queries
    if ! test_available_queries; then
        all_passed=false
    fi
    echo ""
    
    # Test searchProducts
    if ! test_search_products; then
        all_passed=false
    fi
    echo ""
    
    # Test product schema
    if ! test_product_details; then
        all_passed=false
    fi
    echo ""
    
    # Test user queries
    if ! test_user_query; then
        all_passed=false
    fi
    echo ""
    
    if ! test_all_users; then
        all_passed=false
    fi
    echo ""
    
    if [ "$all_passed" = true ]; then
        print_success "All router tests passed! 🎉"
        return 0
    else
        print_error "Some router tests failed! ❌"
        return 1
    fi
}

# Function to test basic infrastructure
test_basic_infrastructure() {
    print_status "Testing basic infrastructure..."
    echo ""
    
    local all_passed=true
    
    # Test if we can source the utils
    if source "$SCRIPT_DIR/utils.sh" > /dev/null 2>&1; then
        print_success "Utils sourced successfully"
    else
        print_error "Failed to source utils"
        all_passed=false
    fi
    
    # Test if we can source test-utils
    if source "$SCRIPT_DIR/test-utils.sh" > /dev/null 2>&1; then
        print_success "Test-utils sourced successfully"
    else
        print_error "Failed to source test-utils"
        all_passed=false
    fi
    
    echo ""
    print_status "Testing router health..."
    
    # Test router health
    if curl -s "$(get_router_health_url)" > /dev/null 2>&1; then
        print_success "Router health check passed"
    else
        print_error "Router health check failed"
        all_passed=false
    fi
    
    echo ""
    
    if [ "$all_passed" = true ]; then
        print_success "Basic infrastructure tests passed! ✅"
        return 0
    else
        print_error "Basic infrastructure tests failed! ❌"
        return 1
    fi
}

# Function to test if port 4000 is listening
test_port_4000_listening() {
    if lsof -i :4000 > /dev/null 2>&1; then
        print_success "Port 4000 is listening"
        return 0
    else
        print_error "Port 4000 is not listening"
        return 1
    fi
}

# Function to show router status
show_router_status() {
    print_status "Router Status:"
    echo "  - URL: $ROUTER_URL"
    echo "  - Health: $HEALTH_ENDPOINT"
    echo "  - GraphQL: $GRAPHQL_ENDPOINT"
    echo ""
    
    if test_port_4000_listening; then
        if test_router_health; then
            print_success "Router is running and healthy"
        else
            print_warning "Router is running but health check failed"
        fi
    else
        print_error "Router is not accessible"
    fi
}

# Function to run a specific test
run_test() {
    case "$1" in
        "basic")
            test_basic_infrastructure
            ;;
        "health")
            test_router_health
            ;;
        "introspection")
            test_graphql_introspection
            ;;
        "queries")
            test_available_queries
            ;;
        "products")
            test_search_products
            ;;
        "product-schema")
            test_product_details
            ;;
        "user")
            test_user_query
            ;;
        "users")
            test_all_users
            ;;
        "port")
            test_port_4000_listening
            ;;
        "status")
            show_router_status
            ;;
        "all"|"comprehensive")
            test_router_comprehensive
            ;;
        *)
            print_error "Unknown test: $1"
            echo "Available tests: basic, health, introspection, queries, products, product-schema, user, users, port, status, all"
            return 1
            ;;
    esac
}

# If script is run directly, run comprehensive test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        test_router_comprehensive
    else
        run_test "$1"
    fi
fi
