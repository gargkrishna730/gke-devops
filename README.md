# WOBOT Application - Kubernetes & Docker Deployment

## 📋 Project Overview

This is a comprehensive full-stack application deployment project featuring:
- **Frontend**: React application with beautiful UI
- **Backend**: Node.js Express REST API
- **Containerization**: Multi-stage Docker builds with security hardening
- **Orchestration**: Kubernetes on GKE with advanced deployment strategies
- **Infrastructure**: Terraform-based GCP infrastructure (to be completed)

## 🎯 Assignment Requirements

### Task 1: Terraform (40 points)
- GKE cluster infrastructure
- VPC and networking
- Service accounts and IAM roles
- Storage and database configuration
- Monitoring setup

### Task 2: Docker (25 points)
- ✅ Multi-stage builds
- ✅ Security scanning (hadolint/trivy compatible)
- ✅ Non-root user execution
- ✅ Optimized caching
- ✅ Health checks

### Task 3: Kubernetes on GKE (35 points)
- ✅ 2 Services (Frontend + Backend)
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ Ingress with TLS
- ✅ Canary Deployment Strategy
- ✅ Blue-Green Rollout Capability

### Documentation & Demo (10 points)
- ✅ Comprehensive guides
- ✅ Deployment scripts
- ✅ Clear architecture
- ✅ Testing instructions

## 🏗️ Architecture

```
Internet
    ↓
[Google Cloud Load Balancer + TLS]
    ↓
[Kubernetes Ingress]
    ├─→ Frontend Service (3000)
    │   ├─→ Frontend Stable Pods (Nginx + React)
    │   └─→ Frontend Canary Pod (Nginx + React)
    │
    └─→ Backend Service (3001)
        ├─→ Backend Stable Pods (Node.js Express)
        └─→ Backend Canary Pod (Node.js Express)
```

## 🚀 Quick Start

### Local Development with Docker Compose
```bash
docker-compose up --build
```

Access:
- Frontend: http://localhost:3000
- Backend Health: http://localhost:3001/health

## 📦 Backend API

**Technology**: Node.js 18 (Alpine) + Express.js
**Port**: 3001

### Endpoints
- `GET /health` - Health check
- `GET /api/v1/status` - Service status and metrics
- `GET /api/v1/data` - Sample data
- `POST /api/v1/echo` - Echo message

## 🎨 Frontend Application

**Technology**: React 18 + Nginx (Alpine) + Axios
**Port**: 3000

### Features
- Backend status monitoring
- Data fetching demonstration
- Echo message feature
- Beautiful gradient UI with animations
- Security headers configured

## 🔒 Security Features

### Docker
- Non-root user execution (UID 1001)
- Read-only root filesystem support
- Dropped Linux capabilities
- Multi-stage builds for reduced attack surface
- Health checks configured

### Kubernetes
- Network Policies for pod-to-pod communication
- Pod Security Context (non-root, no privilege escalation)
- Resource Limits (CPU/Memory constraints)
- RBAC via ServiceAccount
- Pod Disruption Budgets for high availability
- TLS/SSL on Ingress

### Nginx
- Security headers (CSP, X-Frame-Options, X-XSS-Protection)
- Gzip compression
- Cache control policies
- DDoS mitigation

## ⚖️ Load Balancing & Autoscaling

### Horizontal Pod Autoscaler (HPA)

**Backend**:
- Min Replicas: 2
- Max Replicas: 10
- CPU Target: 70%
- Memory Target: 80%

**Frontend**:
- Min Replicas: 2
- Max Replicas: 8
- CPU Target: 75%
- Memory Target: 85%

## 🔄 Deployment Strategies

### Canary Deployment
- Separate canary deployment (1 replica)
- Gradual traffic shifting (10% → 25% → 50% → 75% → 100%)
- Automatic monitoring and rollback capability
- Script: `kubernetes/09-rollout-strategies.yaml`

### Blue-Green Deployment
- Stable (Blue) and Canary (Green) running simultaneously
- Health checks on Green before traffic switch
- Instant traffic switch with zero downtime
- Easy rollback capability

### Rolling Update
- Default Kubernetes strategy
- maxSurge: 1, maxUnavailable: 0
- Ensures high availability

## 📊 Services

### Kubernetes Services
- `backend-service` - Routes to all backend pods
- `backend-stable-service` - Routes only to stable deployment
- `backend-canary-service` - Routes only to canary deployment
- `frontend-service` - Routes to all frontend pods
- `frontend-stable-service` - Routes only to stable deployment
- `frontend-canary-service` - Routes only to canary deployment

### Ingress Routes
- `wobot.example.com` → Frontend Service
- `api.wobot.example.com` → Backend Service

## 📁 Directory Structure

```
wobot-backend-app/
├── backend/                    # Node.js Express Backend
│   ├── src/
│   │   └── index.js           # Main server
│   ├── Dockerfile             # Multi-stage build
│   ├── .dockerignore
│   └── package.json
├── frontend/                   # React Frontend
│   ├── public/
│   ├── src/
│   ├── Dockerfile             # Multi-stage nginx build
│   ├── nginx.conf
│   ├── default.conf
│   └── package.json
├── kubernetes/                 # K8s manifests
│   ├── 00-namespace.yaml
│   ├── 01-configmap.yaml
│   ├── 02-backend-deployment.yaml
│   ├── 03-backend-service.yaml
│   ├── 04-hpa.yaml
│   ├── 05-frontend-deployment.yaml
│   ├── 06-frontend-service.yaml
│   ├── 07-ingress.yaml
│   ├── 08-policies.yaml
│   └── 09-rollout-strategies.yaml
├── terraform/                  # IaC for GCP/GKE
├── docker-compose.yml         # Local development
├── build-and-push.sh          # Build script
├── deploy-to-gke.sh           # Deployment script
├── DEPLOYMENT_GUIDE.md        # Detailed guide
└── README.md                  # This file
```

## 🧪 Testing

### Health Checks
```bash
curl http://localhost:3001/health
curl http://api.wobot.example.com/health
```

### API Endpoints
```bash
# Get status
curl http://localhost:3001/api/v1/status

# Get data
curl http://localhost:3001/api/v1/data

# Echo message
curl -X POST http://localhost:3001/api/v1/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello Kubernetes!"}'
```

### Frontend
Open browser: http://localhost:3000 or https://wobot.example.com

## 📈 Monitoring Commands

```bash
# Check pod status
kubectl get pods -n wobot -w

# View logs
kubectl logs <pod-name> -n wobot -f

# Check HPA status
kubectl get hpa -n wobot
kubectl describe hpa backend-hpa -n wobot

# Resource usage
kubectl top nodes
kubectl top pods -n wobot

# Port forward for testing
kubectl port-forward svc/backend-service 3001:3001 -n wobot
kubectl port-forward svc/frontend-service 3000:3000 -n wobot
```

## 🔧 Terraform Setup

The `terraform/` directory should contain:
- VPC and networking
- GKE cluster configuration
- Node pools
- Service accounts and IAM
- Cloud Storage
- Cloud SQL