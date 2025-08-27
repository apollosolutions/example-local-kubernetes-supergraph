#!/bin/bash

# =============================================================================
# Apollo Supergraph - Environment Setup Script
# =============================================================================
#
# This script safely sets up the Apollo Studio environment for the Apollo Router.
# It will create the .env file from the template if it doesn't exist, and
# provide instructions for getting your Apollo Studio credentials.
#
# =============================================================================

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

ENV_FILE="router/.env"
TEMPLATE_FILE="router/env.example"

show_script_header "Environment Setup" "Setting up Apollo Studio environment"

# Check if .env file already exists
if file_exists "$ENV_FILE"; then
    print_warning "$ENV_FILE already exists!"
    echo ""
    echo "Current contents:"
    echo "=================="
    cat "$ENV_FILE"
    echo "=================="
    echo ""
    echo "If you need to update your credentials, edit the file manually:"
    echo "  $EDITOR $ENV_FILE"
    echo ""
    print_success "Environment is already configured!"
    exit 0
fi

# Check if template exists
if ! file_exists "$TEMPLATE_FILE"; then
    print_error "Template file $TEMPLATE_FILE not found!"
    exit 1
fi

# Create .env file from template
print_status "Creating $ENV_FILE from template..."
cp "$TEMPLATE_FILE" "$ENV_FILE"
print_success "Created $ENV_FILE"

echo ""
echo "📝 Next Steps:"
echo "=============="
echo ""
echo "1. Get your Apollo Studio credentials:"
echo "   - Go to https://studio.apollographql.com/"
echo "   - Create or select your graph"
echo "   - Go to Settings > API Keys"
echo "   - Create a new API key with 'Observer' or higher permissions"
echo ""
echo "2. Edit the .env file with your credentials:"
echo "   $EDITOR $ENV_FILE"
echo ""
echo "3. The .env file should contain:"
echo "   APOLLO_GRAPH_REF=your-graph-name@your-variant"
echo "   APOLLO_KEY=service:your-graph-name:your-api-key"
echo ""
echo "4. Test your setup:"
echo "   ./run-local.sh --help"
echo ""

print_success "Environment setup completed!"
print_warning "Remember to add your actual Apollo Studio credentials to $ENV_FILE"

show_script_footer "Environment Setup"
