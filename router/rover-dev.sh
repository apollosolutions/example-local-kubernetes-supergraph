set -e

# Start the router sourcing the graph ref and API key from .env
source .env

rover dev \
  --supergraph-config supergraph.yaml \
  --router-config router.yaml
