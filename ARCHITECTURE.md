# Apollo Supergraph - Architecture Guide

Technical details and architecture explanations for the Apollo Supergraph project.

## 🏗️ Architecture Overview

This project demonstrates an Apollo Supergraph with:

- **Apollo Router** - GraphQL gateway that routes requests to subgraphs
- **Subgraphs** - Three GraphQL services (Products, Reviews, Users) in a monolithic Node.js application
- **Multiple deployment modes** - Local development and Kubernetes deployment

## 🔄 Deployment Modes

### Local Development Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Apollo Router │    │   Subgraphs     │    │   Development   │
│   (Docker)      │◄──►│   (Node.js)     │    │   Environment   │
│   Port 4000     │    │   Port 4001     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Components:**
- **Apollo Router**: Runs in Docker container on port 4000
- **Subgraphs**: Runs as Node.js process on port 4001
- **Communication**: Direct localhost connections
- **Supergraph**: Generated with localhost URLs

**Benefits:**
- ✅ Fast startup and development cycle
- ✅ Direct access to logs and debugging
- ✅ No resource constraints
- ✅ Simple cleanup (Ctrl+C)

### Kubernetes Deployment Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Apollo Router │    │   Subgraphs     │
│   Controller    │◄──►│   (K8s Pods)    │◄──►│   (K8s Pods)    │
│   Port 80       │    │   Port 4000     │    │   Port 4001     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Components:**
- **Ingress Controller**: Nginx ingress for external access
- **Apollo Router**: Runs in Kubernetes pods on port 4000
- **Subgraphs**: Runs in Kubernetes pods on port 4001
- **Services**: ClusterIP services for internal communication
- **Supergraph**: Generated with Kubernetes service URLs

**Benefits:**
- ✅ Production-like environment
- ✅ Scalable and resilient
- ✅ Resource management
- ✅ Service discovery

## 📁 Project Structure

```
example-local-kubernetes-supergraph/
├── router/                    # Apollo Router configuration
│   ├── router.yaml           # Router configuration
│   ├── supergraph.yaml       # Supergraph composition config
│   ├── supergraph.graphql    # Generated supergraph schema
│   ├── compose.sh            # Generate supergraph schema
│   └── .env                  # Apollo Studio credentials
├── subgraphs/                # GraphQL subgraphs
│   ├── products/             # Products subgraph
│   │   ├── schema.graphql    # GraphQL schema
│   │   ├── resolvers.js      # Resolver functions
│   │   └── data.js           # Mock data
│   ├── reviews/              # Reviews subgraph
│   ├── users/                # Users subgraph
│   ├── subgraphs.js          # Subgraph registration
│   ├── index.js              # Main application
│   ├── package.json          # Dependencies
│   └── Dockerfile            # Container image
├── k8s/                      # Kubernetes manifests
│   ├── namespace.yaml        # Kubernetes namespace
│   ├── subgraphs-deployment-clusterip.yaml  # Subgraphs deployment
│   ├── router-deployment-clusterip.yaml     # Router deployment
│   └── ingress.yaml          # Ingress configuration
├── scripts/                  # Internal utilities
│   ├── utils.sh              # Shared utilities
│   ├── test-utils.sh         # Test operations
│   ├── port-forward-utils.sh # Centralized port forwarding management
│   └── build-validate.sh     # Build validation
├── run-local.sh              # Local development
├── run-k8s.sh                # Kubernetes deployment
├── test-router.sh            # Router testing
├── test-k8s.sh               # Deployment validation
├── setup-minikube.sh         # Minikube setup
├── setup-env.sh              # Environment setup
├── cleanup-k8s.sh            # Kubernetes cleanup
└── kill-minikube.sh          # Minikube cleanup
```

## 🔧 Technical Details

### Supergraph Composition

The supergraph is composed using Apollo Rover:

```bash
# Generate supergraph from subgraph schemas
cd router
rover supergraph compose --config supergraph.yaml
```

**supergraph.yaml:**
```yaml
federation_version: =2.5.0
subgraphs:
  products:
    routing_url: http://localhost:4001/products/graphql
    schema:
      subgraph_url: http://localhost:4001/products/graphql
  reviews:
    routing_url: http://localhost:4001/reviews/graphql
    schema:
      subgraph_url: http://localhost:4001/reviews/graphql
  users:
    routing_url: http://localhost:4001/users/graphql
    schema:
      subgraph_url: http://localhost:4001/users/graphql
```

### URL Transformation

For Kubernetes deployment, localhost URLs are transformed to Kubernetes service URLs:

**Local Development:**
```
http://localhost:4001/products/graphql
```

**Kubernetes Deployment:**
```
http://subgraphs-service.apollo-supergraph.svc.cluster.local:4001/products/graphql
```

### Kubernetes Services

**Subgraphs Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: subgraphs-service
  namespace: apollo-supergraph
spec:
  selector:
    app: subgraphs
  ports:
    - port: 4001
      targetPort: 4001
  type: ClusterIP
```

**Router Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: apollo-router-service
  namespace: apollo-supergraph
spec:
  selector:
    app: apollo-router
  ports:
    - name: graphql
      port: 4000
      targetPort: 4000
    - name: health
      port: 8088
      targetPort: 8088
  type: ClusterIP
```

## 🔍 Debugging Commands

### Local Development

```bash
# View subgraphs logs
cd subgraphs && npm start

# View router logs
docker logs <router-container-id>

# Test subgraphs directly
curl -X POST http://localhost:4001/products/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title } }"}'

# Test router
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ searchProducts { id title } }"}'
```

### Kubernetes Deployment

```bash
# View all resources
kubectl get all -n apollo-supergraph

# View pods
kubectl get pods -n apollo-supergraph

# View services
kubectl get svc -n apollo-supergraph

# View router logs
kubectl logs -f deployment/apollo-router -n apollo-supergraph

# View subgraphs logs
kubectl logs -f deployment/subgraphs -n apollo-supergraph

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n apollo-supergraph

# Port forward for direct access
kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph
kubectl port-forward svc/subgraphs-service 4001:4001 -n apollo-supergraph

# Check ingress
kubectl get ingress -n apollo-supergraph
kubectl describe ingress apollo-router-ingress -n apollo-supergraph
```

### Network Connectivity

```bash
# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -n apollo-supergraph -- \
  wget -qO- http://subgraphs-service:4001/products/graphql

# Check DNS resolution
kubectl run test-pod --image=busybox --rm -it --restart=Never -n apollo-supergraph -- \
  nslookup subgraphs-service.apollo-supergraph.svc.cluster.local
```

## 🔐 Security Considerations

### Apollo Studio Credentials

- **Environment Variables**: Stored in `router/.env`
- **Kubernetes**: Passed as environment variables (not secrets for demo)
- **Production**: Use Kubernetes Secrets for sensitive data

### Network Security

- **Local Development**: Direct localhost access
- **Kubernetes**: ClusterIP services (internal only)
- **External Access**: Via Ingress controller

## 📊 Performance Considerations

### Resource Limits

**Default Limits:**
- **Router**: 256MB RAM, 200m CPU
- **Subgraphs**: 256MB RAM, 200m CPU

**Scaling:**
- **Horizontal**: Multiple replicas via `--replicas` flag
- **Vertical**: Adjust resource limits in deployment files

### Optimization

- **Supergraph Caching**: Router caches composed supergraph
- **Connection Pooling**: Router manages connections to subgraphs
- **Load Balancing**: Kubernetes services distribute load across pods
