# Apollo Supergraph - Local Development & Kubernetes Deployment

A complete example of deploying an Apollo Supergraph (Router + Subgraphs) for both local development and Kubernetes deployment.

## 🚀 Quick Start

### Option 1: Local Development (Recommended for Development)

Run the Apollo Supergraph locally without Kubernetes:

```bash
# Run both subgraphs and router
./run-local.sh



# Show help
./run-local.sh --help
```

**Benefits of local development:**
- ✅ **Faster startup** - No Kubernetes overhead
- ✅ **Easier debugging** - Direct access to logs
- ✅ **No resource constraints** - Runs directly on your machine
- ✅ **Simple cleanup** - Just Ctrl+C to stop

### Option 2: Kubernetes Deployment (Recommended for Testing Production-like Environment)

#### Setup minikube

```bash
# Setup minikube with required addons
./setup-minikube.sh
```

#### Deploy the applications

```bash
# Deploy Apollo Supergraph with 2 replicas (default)
./run-k8s.sh

# Deploy with custom number of replicas
./run-k8s.sh --replicas 3

# Show help
./run-k8s.sh --help
```

## 📋 Prerequisites

- [Node.js](https://nodejs.org/) (for subgraphs)
- [Docker](https://docs.docker.com/get-docker/) (for Kubernetes deployment)
- [minikube](https://minikube.sigs.k8s.io/docs/start/) (for Kubernetes deployment)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for Kubernetes deployment)

## 🔧 Configuration

Set up your Apollo Studio environment:

```bash
# Set up Apollo Studio credentials (safe - won't overwrite existing)
./setup-env.sh
```

## 🧪 Testing

### Local Testing

```bash
# Run all local tests
./test-local.sh

# Test specific components
./test-local.sh --subgraphs     # Test subgraphs only
./test-local.sh --composition   # Test supergraph composition only
./test-local.sh --docker        # Test Docker builds only
./test-local.sh --router        # Test router only
```

### Kubernetes Testing

```bash
# Test Apollo Supergraph deployment
./test-k8s.sh
```

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

## 📚 Documentation

- **[SETUP.md](SETUP.md)** - Detailed setup and configuration instructions
- **[README-K8S.md](README-K8S.md)** - Kubernetes-specific deployment details

## 🔗 Links

- [GraphOS Enterprise]: https://www.apollographql.com/docs/graphos/enterprise
- [Rover]: https://www.apollographql.com/docs/rover/commands/dev
- [minikube]: https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fhomebrew
