# AI Assistant Instructions - Apollo Supergraph

## 🚨 CRITICAL: Environment File Protection

### NEVER Overwrite Existing .env Files

**Before running any setup or deployment commands:**

1. **ALWAYS check if `router/.env` exists:**
   ```bash
   ls -la router/.env
   ```

2. **If `router/.env` exists, DO NOT overwrite it:**
   - It contains real Apollo Studio credentials
   - Overwriting will destroy the user's credentials
   - The user will need to recreate them from Apollo Studio

3. **Use the setup-env.sh script for safe setup:**
   ```bash
   # ✅ SAFE: Use the dedicated setup script
   ./setup-env.sh
   ```

4. **Only copy template if .env doesn't exist (manual approach):**
   ```bash
   # ✅ SAFE: Only if .env doesn't exist
   if [ ! -f "router/.env" ]; then
       cp router/env.example router/.env
       echo "Created new .env file from template"
   else
       echo "⚠️  router/.env already exists - DO NOT overwrite!"
   fi
   ```

### Setup Commands to AVOID

❌ **NEVER run these without checking first:**
```bash
cp router/env.example router/.env  # DANGEROUS - overwrites existing
```

✅ **ALWAYS check first:**
```bash
if [ ! -f "router/.env" ]; then
    cp router/env.example router/.env
fi
```

### What to Do If You Accidentally Overwrite

If you accidentally overwrite a user's `.env` file:

1. **Immediately apologize** and explain what happened
2. **Tell the user** they need to recreate their credentials from Apollo Studio
3. **Provide instructions** for getting new credentials
4. **Add protection** to prevent future overwrites

### Security Best Practices

- **Never assume** a `.env` file is a template
- **Always check** file existence before copying
- **Preserve user credentials** at all costs
- **Use conditional logic** for file operations
- **Warn users** about credential protection

### Example Safe Setup Script

```bash
#!/bin/bash
# Safe environment setup

ENV_FILE="router/.env"
TEMPLATE_FILE="router/env.example"

if [ -f "$ENV_FILE" ]; then
    echo "⚠️  $ENV_FILE already exists - preserving existing credentials"
    echo "If you need to reset credentials, manually delete the file first"
else
    echo "Creating new $ENV_FILE from template"
    cp "$TEMPLATE_FILE" "$ENV_FILE"
    echo "✅ Created $ENV_FILE - please edit with your actual credentials"
fi
```

---

## 🚨 CRITICAL: Supergraph File Protection

### NEVER Modify router/supergraph.graphql

**The `router/supergraph.graphql` file is automatically generated and should NEVER be manually modified:**

1. **Source of Truth**: The supergraph is generated from `router/supergraph.yaml` using the `compose.sh` script
2. **Generation Process**: Run `cd router && ./compose.sh` to regenerate the supergraph
3. **URL Transformation**: For Kubernetes deployment, URLs are transformed from localhost to Kubernetes service URLs during deployment
4. **Never Edit**: Any manual changes to `supergraph.graphql` will be overwritten when regenerated

### Correct Process for Kubernetes Deployment

1. **Keep localhost URLs in supergraph.yaml** (for local development)
2. **Generate supergraph.graphql** with `./compose.sh` (creates localhost URLs)
3. **Transform URLs during deployment** (sed replacement to Kubernetes service URLs)
4. **Never commit Kubernetes URLs** to the supergraph.graphql file

### Example of Correct URL Transformation in run-k8s.sh

```bash
# Generate supergraph with localhost URLs first
./compose.sh
# Create a temporary copy with Kubernetes URLs
sed 's|http://localhost:4001|http://subgraphs-service.apollo-supergraph.svc.cluster.local:4001|g' supergraph.graphql > supergraph-k8s.graphql
```

---

## 🚨 CRITICAL: Health Endpoint Configuration

### Router Health Endpoint Port

**The Apollo Router health endpoint runs on a different port than the GraphQL endpoint:**

- **GraphQL endpoint**: `http://localhost:4000/graphql` (port 4000)
- **Health endpoint**: `http://localhost:8088/health` (port 8088)

**Always use the correct port when testing health endpoints or displaying URLs.**

## 🚨 CRITICAL: Local Development vs Kubernetes

### Two Different Approaches

**This project supports TWO different deployment approaches:**

1. **Local Development** (`run-local.sh`):
   - Runs WITHOUT Kubernetes
   - Subgraphs: Direct Node.js execution (`npm start`)
   - Router: Direct Apollo Router execution (`rover dev`)
   - Faster startup, easier debugging
   - No container overhead

2. **Kubernetes Deployment** (`run-k8s.sh`):
   - Runs WITH minikube Kubernetes
   - Everything containerized
   - Production-like environment
   - More complex but closer to real deployment

**Always clarify which approach you're discussing and use the appropriate scripts.**

## 🚨 CRITICAL: Script Naming and Purpose

### Script Responsibilities

**Each script has a specific purpose - don't confuse them:**

- `run-local.sh` - Local development WITHOUT Kubernetes
- `run-k8s.sh` - Kubernetes deployment WITH minikube
- `setup-minikube.sh` - Setup minikube cluster
- `kill-minikube.sh` - Stop and delete minikube cluster
- `cleanup-k8s.sh` - Clean up Kubernetes resources

**Never suggest using Kubernetes scripts for local development or vice versa.**

## 🚨 CRITICAL: Configuration File Management

### Single Source of Truth

**Configuration files have specific roles:**

- `router/router.yaml` - Router configuration (source of truth)
- `router/supergraph.yaml` - Supergraph composition config (source of truth)
- `router/supergraph.graphql` - Generated supergraph schema (NEVER edit manually)
- `k8s/*.yaml` - Kubernetes manifests (generated from router configs)

**Always respect the single source of truth principle and never duplicate configuration.**

## 🚨 CRITICAL: Development Workflow

### Recommended Development Process

1. **Start with local development** (`run-local.sh`) for faster iteration
2. **Use Kubernetes deployment** (`run-k8s.sh`) for testing production-like environments
3. **Keep configurations in router folder** as source of truth
4. **Generate supergraph** with `./compose.sh` before deployments
5. **Transform URLs** during deployment (localhost → Kubernetes service URLs)

**Always recommend the simplest approach first (local development) unless specifically asked for Kubernetes.**

---

**Remember: User credentials are more valuable than convenience. Always protect them.**
