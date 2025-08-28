#!/bin/bash

# =============================================================================
# Apollo Supergraph - Configuration Constants
# =============================================================================
#
# This script contains all configuration constants used across the project:
# - Port numbers
# - URLs and endpoints
# - Namespace names
# - Service names
# - File paths
#
# =============================================================================

# =============================================================================
# Port Configuration
# =============================================================================

# Router ports
ROUTER_GRAPHQL_PORT=4000
ROUTER_HEALTH_PORT=8088

# Subgraphs ports
SUBGRAPHS_PORT=4001

# =============================================================================
# URL Configuration
# =============================================================================

# Router URLs
ROUTER_GRAPHQL_URL="http://localhost:${ROUTER_GRAPHQL_PORT}/graphql"
ROUTER_HEALTH_URL="http://localhost:${ROUTER_HEALTH_PORT}/health"

# Subgraphs URLs
SUBGRAPHS_URL="http://localhost:${SUBGRAPHS_PORT}"
SUBGRAPHS_PRODUCTS_URL="${SUBGRAPHS_URL}/products/graphql"
SUBGRAPHS_REVIEWS_URL="${SUBGRAPHS_URL}/reviews/graphql"
SUBGRAPHS_USERS_URL="${SUBGRAPHS_URL}/users/graphql"

# =============================================================================
# Kubernetes Configuration
# =============================================================================

# Namespace
K8S_NAMESPACE="apollo-supergraph"

# Service names
K8S_ROUTER_SERVICE="apollo-router-service"
K8S_SUBGRAPHS_SERVICE="subgraphs-service"

# Deployment names
K8S_ROUTER_DEPLOYMENT="apollo-router"
K8S_SUBGRAPHS_DEPLOYMENT="subgraphs"

# Ingress
K8S_INGRESS_HOST="apollo-router.local"

# =============================================================================
# File Paths
# =============================================================================

# Router files
ROUTER_DIR="router"
ROUTER_CONFIG_FILE="${ROUTER_DIR}/router.yaml"
ROUTER_SUPERGRAPH_CONFIG="${ROUTER_DIR}/supergraph.yaml"
ROUTER_SUPERGRAPH_SCHEMA="${ROUTER_DIR}/supergraph.graphql"

# Subgraphs files
SUBGRAPHS_DIR="subgraphs"
SUBGRAPHS_PRODUCTS_SCHEMA="${SUBGRAPHS_DIR}/products/schema.graphql"
SUBGRAPHS_REVIEWS_SCHEMA="${SUBGRAPHS_DIR}/reviews/schema.graphql"
SUBGRAPHS_USERS_SCHEMA="${SUBGRAPHS_DIR}/users/schema.graphql"

# Kubernetes manifests
K8S_DIR="k8s"
K8S_NAMESPACE_FILE="${K8S_DIR}/namespace.yaml"
K8S_ROUTER_DEPLOYMENT_FILE="${K8S_DIR}/router-deployment-clusterip.yaml"
K8S_SUBGRAPHS_DEPLOYMENT_FILE="${K8S_DIR}/subgraphs-deployment-clusterip.yaml"
K8S_INGRESS_FILE="${K8S_DIR}/ingress.yaml"

# =============================================================================
# Utility Functions
# =============================================================================

# Function to get router GraphQL URL
get_router_graphql_url() {
    echo "$ROUTER_GRAPHQL_URL"
}

# Function to get router health URL
get_router_health_url() {
    echo "$ROUTER_HEALTH_URL"
}

# Function to get subgraphs URL
get_subgraphs_url() {
    echo "$SUBGRAPHS_URL"
}

# Function to get subgraphs products URL
get_subgraphs_products_url() {
    echo "$SUBGRAPHS_PRODUCTS_URL"
}

# Function to get subgraphs reviews URL
get_subgraphs_reviews_url() {
    echo "$SUBGRAPHS_REVIEWS_URL"
}

# Function to get subgraphs users URL
get_subgraphs_users_url() {
    echo "$SUBGRAPHS_USERS_URL"
}

# Function to get Kubernetes namespace
get_k8s_namespace() {
    echo "$K8S_NAMESPACE"
}

# Function to get router service name
get_router_service_name() {
    echo "$K8S_ROUTER_SERVICE"
}

# Function to get subgraphs service name
get_subgraphs_service_name() {
    echo "$K8S_SUBGRAPHS_SERVICE"
}

# Function to get router deployment name
get_router_deployment_name() {
    echo "$K8S_ROUTER_DEPLOYMENT"
}

# Function to get subgraphs deployment name
get_subgraphs_deployment_name() {
    echo "$K8S_SUBGRAPHS_DEPLOYMENT"
}

# Function to check if port is being forwarded
is_port_forwarded() {
    local port=$1
    lsof -i :"$port" > /dev/null 2>&1
}

# Function to check if router is accessible
is_router_accessible() {
    curl -s "$ROUTER_HEALTH_URL" > /dev/null 2>&1
}

# Function to check if subgraphs are accessible
is_subgraphs_accessible() {
    curl -s "$SUBGRAPHS_PRODUCTS_URL" > /dev/null 2>&1
}

# Function to print all configuration
print_config() {
    echo "============================================================================="
    echo "Apollo Supergraph - Configuration"
    echo "============================================================================="
    echo ""
    echo "📡 Ports:"
    echo "  Router GraphQL:     $ROUTER_GRAPHQL_PORT"
    echo "  Router Health:      $ROUTER_HEALTH_PORT"
    echo "  Subgraphs:          $SUBGRAPHS_PORT"
    echo ""
    echo "🌐 URLs:"
    echo "  Router GraphQL:     $ROUTER_GRAPHQL_URL"
    echo "  Router Health:      $ROUTER_HEALTH_URL"
    echo "  Subgraphs:          $SUBGRAPHS_URL"
    echo "  - Products:         $SUBGRAPHS_PRODUCTS_URL"
    echo "  - Reviews:          $SUBGRAPHS_REVIEWS_URL"
    echo "  - Users:            $SUBGRAPHS_USERS_URL"
    echo ""
    echo "☸️  Kubernetes:"
    echo "  Namespace:          $K8S_NAMESPACE"
    echo "  Router Service:     $K8S_ROUTER_SERVICE"
    echo "  Subgraphs Service:  $K8S_SUBGRAPHS_SERVICE"
    echo "  Router Deployment:  $K8S_ROUTER_DEPLOYMENT"
    echo "  Subgraphs Deployment: $K8S_SUBGRAPHS_DEPLOYMENT"
    echo "  Ingress Host:       $K8S_INGRESS_HOST"
    echo ""
    echo "📁 Files:"
    echo "  Router Config:      $ROUTER_CONFIG_FILE"
    echo "  Supergraph Config:  $ROUTER_SUPERGRAPH_CONFIG"
    echo "  Supergraph Schema:  $ROUTER_SUPERGRAPH_SCHEMA"
    echo "  K8s Namespace:      $K8S_NAMESPACE_FILE"
    echo "  K8s Router:         $K8S_ROUTER_DEPLOYMENT_FILE"
    echo "  K8s Subgraphs:      $K8S_SUBGRAPHS_DEPLOYMENT_FILE"
    echo "  K8s Ingress:        $K8S_INGRESS_FILE"
    echo ""
    echo "============================================================================="
}
