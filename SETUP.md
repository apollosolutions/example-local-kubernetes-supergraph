# Apollo Supergraph - Setup Guide

Complete guide to set up and run the Apollo Supergraph locally and in Kubernetes.

## 📋 Prerequisites

- [Node.js](https://nodejs.org/) (for subgraphs)
- [Docker](https://docs.docker.com/get-docker/) (for Kubernetes deployment)
- [minikube](https://minikube.sigs.k8s.io/docs/start/) (for Kubernetes deployment)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for Kubernetes deployment)

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Set up Apollo Studio credentials (safe - won't overwrite existing)
./setup-env.sh
```

### 2. Choose Your Deployment Option

#### Option A: Local Development (Recommended for Development)

```bash
# Run both subgraphs and router
./run-local.sh

# Test the router
./test-router.sh products
```

**Benefits:**
- ✅ **Faster startup** - No Kubernetes overhead
- ✅ **Easier debugging** - Direct access to logs
- ✅ **No resource constraints** - Runs directly on your machine
- ✅ **Simple cleanup** - Just Ctrl+C to stop

#### Option B: Kubernetes Deployment (Recommended for Testing Production-like Environment)

```bash
# Setup minikube with required addons
./setup-minikube.sh

# Deploy Apollo Supergraph with 2 replicas (default)
./run-k8s.sh

# Validate the deployment worked
./test-k8s.sh

# Test specific router functionality
./test-router.sh products
```

## 🧪 Testing

### Router Testing (After Deployment)

```bash
# Test Apollo Router functionality
./test-router.sh

# Test specific functionality
./test-router.sh products          # Test searchProducts query
./test-router.sh status            # Show router status
./test-router.sh health            # Test health endpoint

# Show all available tests
./test-router.sh --help
```

**When to use**: After deployment is running, to test specific router features or debug issues.

### Deployment Validation (After Running run-k8s.sh)

```bash
# Test the entire Kubernetes deployment
./test-k8s.sh
```

**When to use**: After running `./run-k8s.sh`, to validate that the entire deployment (subgraphs + router) is working correctly.

### Test Script Differences

| Script | Purpose | Scope | When to Use |
|--------|---------|-------|-------------|
| `./test-k8s.sh` | **Deployment validation** | Full deployment (subgraphs + router) | After `./run-k8s.sh` |
| `./test-router.sh` | **Router testing** | Router only | When router is running |
| `./status-k8s.sh` | **Kubernetes status** | K8s resources in minikube | Check deployment status |

### Kubernetes Status Monitoring

The `status-k8s.sh` script provides comprehensive status information about your Kubernetes deployment:

```bash
# Show basic status
./status-k8s.sh

# Show detailed information
./status-k8s.sh --detailed

# Show only pod status
./status-k8s.sh --pods

# Show only service status
./status-k8s.sh --services

# Show only ingress status
./status-k8s.sh --ingress
```

**What it shows:**
- ✅ Pod status and health
- ✅ Service endpoints
- ✅ Deployment status
- ✅ Ingress configuration
- ✅ Port forwarding status
- ✅ Access URLs
- ✅ Resource usage (with --detailed)

## 🧹 Cleanup

### Local Development
```bash
# Stop all services
Ctrl+C (in the terminal running run-local.sh)
```

### Kubernetes Deployment
```bash
# Clean up deployment
./cleanup-k8s.sh

# Stop and delete minikube cluster
./kill-minikube.sh
```

---

## 🔧 Advanced Options

<details>
<summary><strong>Custom Replicas</strong></summary>

```bash
# Deploy with custom number of replicas
./run-k8s.sh --replicas 3

# Show all options
./run-k8s.sh --help
```

</details>

<details>
<summary><strong>Port Forwarding Management</strong></summary>

The project includes improved port forwarding utilities that handle starting, stopping, and monitoring port forwarding automatically:

```bash
# Check port forwarding status
./scripts/port-forward-utils.sh status

# Start all port forwarding (router + subgraphs)
./scripts/port-forward-utils.sh start

# Start only router port forwarding
./scripts/port-forward-utils.sh router

# Start only subgraphs port forwarding
./scripts/port-forward-utils.sh subgraphs

# Stop all port forwarding
./scripts/port-forward-utils.sh stop
```

**Benefits of the new port forwarding system:**
- ✅ **Automatic PID tracking** - No need to manually track process IDs
- ✅ **Conflict prevention** - Won't start duplicate port forwarding
- ✅ **Automatic cleanup** - Stops port forwarding when scripts exit
- ✅ **Status monitoring** - Easy to check what's currently running
- ✅ **Centralized management** - Single utility for all port forwarding needs

**Manual port forwarding (alternative):**
```bash
# Start port forwarding for Apollo Router
kubectl port-forward svc/apollo-router-service 4000:4000 -n apollo-supergraph

# Start port forwarding for subgraphs
kubectl port-forward svc/subgraphs-service 4001:4001 -n apollo-supergraph
```

</details>

<details>
<summary><strong>Access URLs</strong></summary>

After deployment, the Apollo Router is accessible at:

- **GraphQL Endpoint**: http://localhost:4000/graphql
- **Health Check**: http://localhost:4000/health

For direct access to subgraphs:
```bash
# Port forward subgraphs service
kubectl port-forward svc/subgraphs-service 4001:4001 -n apollo-supergraph
```

Then access: http://localhost:4001

</details>

<details>
<summary><strong>Useful Commands</strong></summary>

```bash
# View pods
kubectl get pods -n apollo-supergraph

# View services
kubectl get svc -n apollo-supergraph

# View router logs
kubectl logs -f deployment/apollo-router -n apollo-supergraph

# View subgraphs logs
kubectl logs -f deployment/subgraphs -n apollo-supergraph

# Port forwarding management
./scripts/port-forward-utils.sh status
./scripts/port-forward-utils.sh start
./scripts/port-forward-utils.sh stop

# Manual port forwarding (alternative)
kubectl port-forward svc/subgraphs-service 4001:4001 -n apollo-supergraph
```

</details>

---

## 🚨 Troubleshooting

<details>
<summary><strong>Common Issues</strong></summary>

### Apollo Router fails to start with "no valid license" error

The router requires valid Apollo Studio credentials. You have two options:

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

### NodePort services not accessible

Start minikube tunnel for NodePort access:
```bash
minikube tunnel
```

### Image pull errors

Make sure you're using minikube's Docker daemon:
```bash
eval $(minikube docker-env)
```

### Ingress not working

Check if ingress controller is running:
```bash
kubectl get pods -n ingress-nginx
```

### Service connectivity

Check if services are properly configured:
```bash
kubectl get svc -n apollo-supergraph
kubectl describe svc apollo-router-service -n apollo-supergraph
```

### Pod startup issues

Check pod events and logs:
```bash
kubectl describe pod <pod-name> -n apollo-supergraph
kubectl logs <pod-name> -n apollo-supergraph
```

### Router not connecting to subgraphs

Make sure subgraphs are running:
```bash
# Check if subgraphs are running
kubectl get pods -n apollo-supergraph

# If not running, redeploy
./run-k8s.sh
```

</details>

<details>
<summary><strong>Resource Requirements</strong></summary>

The deployment requires:
- **minikube**: 4GB RAM, 2 CPUs, 20GB disk
- **Applications**: 256MB RAM, 200m CPU per pod

For better performance:
- Increase resource limits in deployment files
- Add horizontal pod autoscalers
- Configure pod disruption budgets
- Use persistent volumes for logs

</details>
