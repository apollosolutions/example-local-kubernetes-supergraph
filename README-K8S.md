# Apollo Supergraph - Kubernetes Deployment Guide

This guide explains how to deploy the Apollo Supergraph (Router + Subgraphs) to a local minikube Kubernetes cluster.

## Architecture Overview

The deployment consists of:

1. **Apollo Router** - GraphQL gateway that routes requests to subgraphs
2. **Subgraphs** - Monolithic Node.js application containing three GraphQL subgraphs:
   - Products
   - Reviews  
   - Users
3. **Ingress** - Nginx ingress controller for external access
4. **Services** - Kubernetes services for internal communication

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Docker](https://docs.docker.com/get-docker/) installed

## Environment Setup

Before deploying, you need to configure your Apollo Studio credentials:

1. **Create environment file**:
   ```bash
   cp router/env.example router/.env
   ```

2. **Edit the `.env` file** with your actual Apollo Studio credentials:
   ```bash
   # Your Apollo Graph reference (format: graph-name@variant)
   APOLLO_GRAPH_REF=your-graph-name@your-variant
   
   # Your Apollo Studio API key
   APOLLO_KEY=service:your-graph-name:your-api-key
   ```

3. **Verify the file is ignored by git**:
   ```bash
   # The .env file should be listed in .gitignore
   cat .gitignore | grep .env
   ```

## Quick Start

### 1. Setup environment

```bash
# Copy and configure your Apollo Studio credentials
cp router/env.example router/.env
# Edit router/.env with your actual credentials
```

### 2. Setup minikube

```bash
# Setup minikube with required addons
./setup-minikube.sh
```

### 3. Deploy the applications

```bash
# Deploy everything to minikube
./deploy.sh
```

### 3. Access the applications

After deployment, you'll need to add the minikube IP to your `/etc/hosts` file:

```bash
# Get minikube IP
minikube ip

# Add to /etc/hosts (replace <minikube-ip> with actual IP)
echo "$(minikube ip) apollo-router.local" | sudo tee -a /etc/hosts
```

Then access:
- **Apollo Router**: http://apollo-router.local
- **Health Check**: http://apollo-router.local:8088

## Security Best Practices

- **Never commit secrets to version control**: The `.env` file is already in `.gitignore`
- **Use Kubernetes Secrets for production**: For production deployments, use Kubernetes Secrets instead of environment variables
- **Rotate API keys regularly**: Keep your Apollo Studio API keys secure and rotate them periodically
- **Limit access**: Only grant necessary permissions to your Apollo Studio API keys

## Manual Deployment Steps

If you prefer to deploy manually, follow these steps:

### 1. Build the subgraphs Docker image

```bash
# Set Docker environment to use minikube's Docker daemon
eval $(minikube docker-env)

# Build the image
cd subgraphs
docker build -t subgraphs:latest .
cd ..
```

### 2. Create namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

### 3. Apply ConfigMaps

```bash
kubectl apply -f k8s/configmaps.yaml
```

### 4. Deploy subgraphs

```bash
kubectl apply -f k8s/subgraphs-deployment.yaml
kubectl wait --for=condition=available --timeout=300s deployment/subgraphs -n apollo-supergraph
```

### 5. Deploy Apollo Router

```bash
kubectl apply -f k8s/router-deployment.yaml
kubectl wait --for=condition=available --timeout=300s deployment/apollo-router -n apollo-supergraph
```

### 6. Apply Ingress

```bash
kubectl apply -f k8s/ingress.yaml
```

## Configuration Details

### Subgraphs Configuration

The subgraphs application runs as a monolithic service with three GraphQL endpoints:
- `/products/graphql` - Product catalog
- `/reviews/graphql` - Product reviews
- `/users/graphql` - User management

### Router Configuration

The Apollo Router is configured to:
- Listen on port 4000
- Connect to subgraphs via Kubernetes service names
- Enable introspection for development
- Include subgraph errors in responses

### Service Discovery

The router connects to subgraphs using Kubernetes service names:
- `http://subgraphs-service.apollo-supergraph.svc.cluster.local:4001/products/graphql`
- `http://subgraphs-service.apollo-supergraph.svc.cluster.local:4001/reviews/graphql`
- `http://subgraphs-service.apollo-supergraph.svc.cluster.local:4001/users/graphql`

## Scaling

Both applications are configured with 2 replicas by default. You can scale them:

```bash
# Scale subgraphs
kubectl scale deployment subgraphs --replicas=3 -n apollo-supergraph

# Scale router
kubectl scale deployment apollo-router --replicas=3 -n apollo-supergraph
```

## Monitoring and Debugging

### View resources

```bash
# View all resources in the namespace
kubectl get all -n apollo-supergraph

# View pods
kubectl get pods -n apollo-supergraph

# View services
kubectl get svc -n apollo-supergraph

# View ingress
kubectl get ingress -n apollo-supergraph
```

### View logs

```bash
# Router logs
kubectl logs -f deployment/apollo-router -n apollo-supergraph

# Subgraphs logs
kubectl logs -f deployment/subgraphs -n apollo-supergraph

# Specific pod logs
kubectl logs -f <pod-name> -n apollo-supergraph
```

### Port forwarding (for local development)

```bash
# Forward router to localhost
kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph

# Forward subgraphs to localhost
kubectl port-forward svc/subgraphs-service 4001:4001 -n apollo-supergraph
```

### Access minikube dashboard

```bash
minikube dashboard
```

## Testing the Deployment

### Test GraphQL queries

```bash
# Test the router
curl -X POST http://apollo-router.local/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ products { id title price } }"}'

# Test subgraphs directly (via port-forward)
curl -X POST http://localhost:4001/products/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ products { id title price } }"}'
```

### Health checks

```bash
# Router health
curl http://apollo-router.local:8088/health

# Subgraphs health
curl http://localhost:4001/products/graphql
```

## Cleanup

To remove all resources:

```bash
./cleanup.sh
```

Or manually:

```bash
kubectl delete namespace apollo-supergraph
```

## Troubleshooting

### Common Issues

1. **Image pull errors**: Make sure you're using minikube's Docker daemon:
   ```bash
   eval $(minikube docker-env)
   ```

2. **Ingress not working**: Check if ingress controller is running:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

3. **Service connectivity**: Check if services are properly configured:
   ```bash
   kubectl get svc -n apollo-supergraph
   kubectl describe svc apollo-router-service -n apollo-supergraph
   ```

4. **Pod startup issues**: Check pod events and logs:
   ```bash
   kubectl describe pod <pod-name> -n apollo-supergraph
   kubectl logs <pod-name> -n apollo-supergraph
   ```

### Resource Requirements

The deployment requires:
- **minikube**: 4GB RAM, 2 CPUs, 20GB disk
- **Applications**: 256MB RAM, 200m CPU per pod

### Performance Tuning

For better performance:
- Increase resource limits in deployment files
- Add horizontal pod autoscalers
- Configure pod disruption budgets
- Use persistent volumes for logs

## File Structure

```
k8s/
├── namespace.yaml           # Kubernetes namespace
├── configmaps.yaml         # Router config and supergraph schema
├── subgraphs-deployment.yaml # Subgraphs deployment and service
├── router-deployment.yaml   # Apollo Router deployment and service
└── ingress.yaml            # Ingress configuration

deploy.sh                   # Main deployment script
cleanup.sh                  # Cleanup script
setup-minikube.sh           # Minikube setup script
subgraphs/Dockerfile        # Subgraphs Docker image
```
