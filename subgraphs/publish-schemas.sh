set -e;

source ../router/.env;

# Extra
rover subgraph publish "$APOLLO_GRAPH_REF" \
  --schema ./extra/schema.graphql \
  --name extra

# Products
rover subgraph publish "$APOLLO_GRAPH_REF" \
  --schema ./products/schema.graphql \
  --name products

# Reviews
rover subgraph publish "$APOLLO_GRAPH_REF" \
  --schema ./reviews/schema.graphql \
  --name reviews

# Transactions
rover subgraph publish "$APOLLO_GRAPH_REF" \
  --schema ./transactions/schema.graphql \
  --name transactions

# Users
rover subgraph publish "$APOLLO_GRAPH_REF" \
  --schema ./users/schema.graphql \
  --name users
