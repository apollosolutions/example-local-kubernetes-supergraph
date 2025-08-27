# Apollo Supergraph - Kubernetes Deployment Guide

This guide provides detailed instructions for deploying the Apollo Supergraph (Router + Subgraphs) to a local minikube Kubernetes cluster.

**For general information and local development, see the main [README.md](README.md).**
**For detailed setup and configuration instructions, see [SETUP.md](SETUP.md).**

## Architecture Overview

The Kubernetes deployment consists of:

1. **Apollo Router** - GraphQL gateway that routes requests to subgraphs
2. **Subgraphs** - Monolithic Node.js application containing three GraphQL subgraphs:
   - Products
   - Reviews  
   - Users
3. **Ingress** - Nginx ingress controller for external access
4. **Services** - Kubernetes services for internal communication

## Quick Start

### Setup minikube

```bash
# Setup minikube with required addons
./setup-minikube.sh
```

### Deploy the applications

Deploy the Apollo Supergraph (router + subgraphs):

```bash
# Deploy Apollo Supergraph
./run-k8s.sh

# Deploy with custom number of replicas
./run-k8s.sh --replicas 3

# Show help
./run-k8s.sh --help
```

### Access the applications

After deployment, you have several options to access the Apollo Router:

**Option 1: Minikube Tunnel (Recommended)**
```bash
# Start minikube tunnel (keep this running in a terminal)
minikube tunnel

# Access via minikube IP
minikube ip  # Get the IP (e.g., 192.168.49.2)
# Then access: http://192.168.49.2:4000/graphql
```

**Option 2: Ingress with /etc/hosts**
```bash
# Get minikube IP
minikube ip

# Add to /etc/hosts (replace <minikube-ip> with actual IP)
echo "$(minikube ip) apollo-router.local" | sudo tee -a /etc/hosts
```

Then access:
- **Apollo Router**: http://apollo-router.local
- **Health Check**: http://apollo-router.local:8088

**Option 3: Port Forwarding**
```bash
# Forward router to localhost
kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph

# Then access: http://localhost:4000/graphql
```

**Note**: If using minikube tunnel, keep the terminal window open while accessing the services.

## Deployment Configuration

### Apollo Supergraph Deployment
- **Namespace**: `apollo-supergraph`
- **Components**: Router + Subgraphs + Ingress
- **Service Type**: ClusterIP (internal communication)
- **Replicas**: 2 each (configurable)
- **Access**: Via Ingress (apollo-router.local) or port forwarding

## Security Best Practices

- **Never commit secrets to version control**: The `.env` file is already in `.gitignore`
- **Use Kubernetes Secrets for production**: For production deployments, use Kubernetes Secrets instead of environment variables
- **Rotate API keys regularly**: Keep your Apollo Studio API keys secure and rotate them periodically
- **Limit access**: Only grant necessary permissions to your Apollo Studio API keys

## Testing

### Kubernetes Testing

```bash
# Test Apollo Supergraph deployment
./test-k8s.sh

# Show help
./test-k8s.sh --help
```

## Cleanup

```bash
# Clean up deployment
./cleanup-k8s.sh

# Stop and delete minikube cluster
./kill-minikube.sh
```

## Troubleshooting

### Common Issues

1. **Apollo Router fails to start with "no valid license" error**: The router requires valid Apollo Studio credentials. You have two options:
   
   **Option A: Use valid Apollo Studio credentials**
   ```bash
   # Edit router/.env with your actual credentials
   APOLLO_GRAPH_REF=your-actual-graph-name@your-variant
   APOLLO_KEY=service:your-actual-graph-name:your-actual-api-key
   ```
   
   **Option B: Run subgraphs locally first**
   ```bash
   # Start subgraphs locally
   cd subgraphs && npm start
   
   # Then deploy router (configured to connect to localhost:4001)
   ./run-k8s.sh
   ```

2. **NodePort services not accessible**: Start minikube tunnel for NodePort access:
   ```bash
   minikube tunnel
   ```

3. **Image pull errors**: Make sure you're using minikube's Docker daemon:
   ```bash
   eval $(minikube docker-env)
   ```

4. **Ingress not working**: Check if ingress controller is running:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

5. **Service connectivity**: Check if services are properly configured:
   ```bash
   kubectl get svc -n <namespace>
   kubectl describe svc <service-name> -n <namespace>
   ```

6. **Pod startup issues**: Check pod events and logs:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

7. **Router not connecting to subgraphs**: Make sure subgraphs are running:
   ```bash
   # Check if subgraphs are running
   kubectl get pods -n apollo-supergraph
   
   # If not running, redeploy
   ./run-k8s.sh
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

run-k8s.sh                  # Kubernetes deployment script
cleanup-k8s.sh              # Kubernetes cleanup script
test-k8s.sh                 # Kubernetes test script
setup-minikube.sh           # Minikube setup script
subgraphs/Dockerfile        # Subgraphs Docker image
```

## Script Options Summary

### run-k8s.sh
- `./run-k8s.sh` - Deploy Apollo Supergraph (router + subgraphs)
- `./run-k8s.sh --replicas N` - Deploy with N replicas
- `./run-k8s.sh --help` - Show help

### cleanup-k8s.sh
- `./cleanup-k8s.sh` - Clean up Apollo Supergraph namespace

### test-k8s.sh
- `./test-k8s.sh` - Test Apollo Supergraph deployment
- `./test-k8s.sh --help` - Show help
