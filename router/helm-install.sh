helm install local-router \
  --namespace apollo-router \
  --set managedFederation.apiKey="service:router-playground:Gi96sNQW_7aLHKfd17GZTA" \
  --set managedFederation.graphRef="router-playground@dev"  \
  oci://ghcr.io/apollographql/helm-charts/router
