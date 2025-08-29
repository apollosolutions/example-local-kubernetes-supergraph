#!/bin/bash

# =============================================================================
# Apollo Supergraph - Shared Utilities
# =============================================================================
#
# This file contains shared utility functions used across the Apollo Supergraph
# deployment scripts.
#
# =============================================================================



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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if minikube is running
minikube_is_running() {
    minikube status | grep -q "Running"
}

# Function to check if minikube is installed
minikube_is_installed() {
    command_exists minikube
}

# Function to check if kubectl is installed
kubectl_is_installed() {
    command_exists kubectl
}

# Function to check if Docker is available
docker_is_available() {
    command_exists docker
}

# Function to validate required tools
validate_required_tools() {
    local missing_tools=()
    
    if ! minikube_is_installed; then
        missing_tools+=("minikube")
    fi
    
    if ! kubectl_is_installed; then
        missing_tools+=("kubectl")
    fi
    
    if ! docker_is_available; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        return 1
    fi
    
    return 0
}

# Function to get minikube IP
get_minikube_ip() {
    minikube ip 2>/dev/null || echo "unknown"
}

# Function to check if namespace exists
namespace_exists() {
    local namespace=$1
    kubectl get namespace "$namespace" >/dev/null 2>&1
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    local timeout=${3:-300}
    
    print_status "Waiting for deployment $deployment to be ready in namespace $namespace..."
    kubectl wait --for=condition=available --timeout="${timeout}s" "deployment/$deployment" -n "$namespace"
}

# Function to check if file exists
file_exists() {
    local file=$1
    [ -f "$file" ]
}

# Function to check if directory exists
directory_exists() {
    local dir=$1
    [ -d "$dir" ]
}

# Function to create directory if it doesn't exist
ensure_directory() {
    local dir=$1
    if ! directory_exists "$dir"; then
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    fi
}

# Function to backup file if it exists
backup_file() {
    local file=$1
    if file_exists "$file"; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_warning "Backed up $file to $backup"
        return 0
    fi
    return 1
}

# Function to restore file from backup
restore_file() {
    local file=$1
    local backup=$2
    if file_exists "$backup"; then
        cp "$backup" "$file"
        print_success "Restored $file from $backup"
        return 0
    fi
    print_error "Backup file $backup not found"
    return 1
}

# Function to show script header
show_script_header() {
    local script_name=$1
    local description=$2
    
    echo "============================================================================="
    echo "Apollo Supergraph - $script_name"
    echo "============================================================================="
    echo "$description"
    echo "============================================================================="
    echo ""
}

# Function to show script footer
show_script_footer() {
    local script_name=$1
    
    echo ""
    echo "============================================================================="
    echo "$script_name completed successfully!"
    echo "============================================================================="
}

# Cross-platform timeout function
run_with_timeout() {
    local timeout_seconds=$1
    shift
    local cmd=("$@")
    
    # Check if timeout command is available (Linux)
    if command -v timeout >/dev/null 2>&1; then
        timeout "${timeout_seconds}s" "${cmd[@]}" 2>/dev/null
        return $?
    fi
    
    # macOS fallback using background process and kill
    local pid
    # Suppress job control messages
    set +m
    "${cmd[@]}" 2>/dev/null &
    pid=$!
    
    # Wait for the specified timeout
    local elapsed=0
    while [ $elapsed -lt $timeout_seconds ]; do
        if ! kill -0 $pid 2>/dev/null; then
            # Process completed
            wait $pid 2>/dev/null
            set -m
            return $?
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    # Timeout reached, kill the process
    kill -TERM $pid 2>/dev/null
    sleep 1
    kill -KILL $pid 2>/dev/null 2>/dev/null
    wait $pid 2>/dev/null
    set -m
    return 124  # Exit code for timeout
}
