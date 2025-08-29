# Apollo Supergraph - Local Development & Kubernetes Deployment

A complete example of deploying an Apollo Supergraph (Router + Subgraphs) for both local development and Kubernetes deployment.

## 🚀 What is this?

This project demonstrates how to set up and deploy an Apollo Supergraph with:

- **Apollo Router** - GraphQL gateway that routes requests to subgraphs
- **Subgraphs** - Three GraphQL services (Products, Reviews, Users) in a monolithic Node.js application
- **Multiple deployment options** - Local development and Kubernetes deployment

## 🎯 Quick Start

**📖 [SETUP.md](SETUP.md) contains the complete guide to get this running.**

The setup guide includes:
- ✅ Prerequisites and installation
- ✅ Local development setup
- ✅ Kubernetes deployment
- ✅ Testing and validation
- ✅ Troubleshooting

## 🏗️ Architecture

This project supports two deployment modes:

### Local Development
- Subgraphs run as Node.js processes
- Router runs in Docker
- Direct localhost access
- Fast development cycle

### Kubernetes Deployment
- Subgraphs run in Kubernetes pods
- Router runs in Kubernetes pods
- Production-like environment
- Scalable and resilient

**📋 [ARCHITECTURE.md](ARCHITECTURE.md) explains the technical details and differences.**

## 🔗 Links

- [GraphOS Enterprise]: https://www.apollographql.com/docs/graphos/enterprise
- [Rover]: https://www.apollographql.com/docs/rover/commands/dev
- [minikube]: https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fhomebrew
