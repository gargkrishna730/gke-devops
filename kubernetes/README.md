# Kubernetes Manifests for Wobot

This directory contains all Kubernetes manifests for deploying the Wobot application (backend and frontend) on Google Kubernetes Engine (GKE).

## Directory Structure

```
kubernetes/
├── 00-namespace.yaml           # Namespace and ServiceAccount setup
├── 01-configmap.yaml           # ConfigMaps for backend and frontend configuration
├── 01-registry-secret.yaml     # Docker registry credentials (reference)
├── 02-backend-deployment.yaml  # Backend deployments (stable + canary)
├── 03-backend-service.yaml     # Backend services (main + stable + canary)
├── 04-hpa.yaml                 # Horizontal Pod Autoscaler for backend and frontend
├── 05-frontend-deployment.yaml # Frontend deployments (stable + canary)
├── 06-frontend-service.yaml    # Frontend services (main + stable + canary)
├── 07-ingress.yaml             # Ingress configuration and BackendConfigs
├── 08-policies.yaml            # Network policies and Pod Disruption Budgets
├── 09-rollout-strategies.yaml  # Canary and blue-green rollout scripts
└── README.md                   # This file
```

## Quick Start

### Prerequisites

1. GKE cluster running and configured
2. `kubectl` configured to access your cluster
3. Docker registry credentials (GCP Artifact Registry)
4. Namespace created in the cluster

### Deploy All Manifests

```bash
# Apply all manifests in order
kubectl apply -f .

# Or apply specific manifests
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-backend-deployment.yaml
kubectl apply -f 05-frontend-deployment.yaml
```

### Verify Deployment

```bash
# Check namespace
kubectl get namespace wobot

# Check all resources
kubectl get all -n wobot

# Check pods
kubectl get pods -n wobot -o wide

# Check services
kubectl get svc -n wobot

# Check deployments
kubectl get deployments -n wobot

# Check ingress
kubectl get ingress -n wobot
```

## File Descriptions

### 00-namespace.yaml
Creates the `wobot` namespace and `wobot-sa` ServiceAccount for running pods.

**Resources:**
- Namespace: `wobot`
- ServiceAccount: `wobot-sa` (with imagePullSecrets for GCP Artifact Registry)

### 01-configmap.yaml
Contains environment variables and configuration for backend and frontend applications.

**ConfigMaps:**
- `backend-config` - Backend environment variables
- `frontend-config` - Frontend environment variables

### 01-registry-secret.yaml
Reference for Docker registry credentials. The secret is created via:

```bash
kubectl create secret docker-registry gcr-json-key \
  --docker-server=us-central1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat /path/to/service-account.json)" \
  --docker-email=service-account@project.iam.gserviceaccount.com \
  -n wobot
```

### 02-backend-deployment.yaml
Deploys the backend application with blue-green and canary deployments.

**Deployments:**
- `backend-stable` (2 replicas) - Production traffic
- `backend-canary` (1 replica) - Testing new versions

**Features:**
- Non-root user (UID: 1001)
- Read-only root filesystem with emptyDir volumes
- Health checks (liveness & readiness probes)
- Rolling update strategy
- Pod anti-affinity for spread across nodes
- Resource limits: 1m CPU, 5Mi memory

### 03-backend-service.yaml
Exposes backend deployments internally and externally.

**Services:**
- `backend-service` - Main service (LoadBalancer, routes to both stable & canary)
- `backend-stable-service` - Direct access to stable deployment
- `backend-canary-service` - Direct access to canary deployment

**Ports:**
- Port 80 (HTTP) → Port 3001
- Port 443 (HTTPS) → Port 3001

### 04-hpa.yaml
Horizontal Pod Autoscaler for automatic scaling based on CPU usage.

**HPAs:**
- `backend-hpa` - Scales backend between 2-5 replicas at 70% CPU
- `frontend-hpa` - Scales frontend between 2-5 replicas at 70% CPU

### 05-frontend-deployment.yaml
Deploys the frontend application with blue-green and canary deployments.

**Deployments:**
- `frontend-stable` (2 replicas) - Production traffic
- `frontend-canary` (1 replica) - Testing new versions

**Features:**
- Non-root user (UID: 1001)
- Read-only root filesystem with emptyDir volumes for nginx
- Health checks (liveness & readiness probes)
- Rolling update strategy
- Pod anti-affinity for spread across nodes
- Resource limits: 1m CPU, 5Mi memory

### 06-frontend-service.yaml
Exposes frontend deployments internally and externally.

**Services:**
- `frontend-service` - Main service (LoadBalancer)
- `frontend-stable-service` - Direct access to stable deployment
- `frontend-canary-service` - Direct access to canary deployment

**Ports:**
- Port 80 (HTTP) → Port 3000
- Port 443 (HTTPS) → Port 3000

### 07-ingress.yaml
Ingress configuration for routing and load balancing with TLS termination.

**Resources:**
- `wobot-ingress` - Routes based on hostname
  - `wobot.example.com` → frontend-service:3000
  - `api.wobot.example.com` → backend-service:3001
- `wobot-cert` - Managed Certificate for TLS
- `backend-backendconfig` - GCP BackendConfig for backend
- `frontend-backendconfig` - GCP BackendConfig for frontend

**Features:**
- GCP-managed SSL certificates
- Session affinity for backend
- Connection draining (60s)
- Logging enabled

### 08-policies.yaml
Network policies and Pod Disruption Budgets for resilience.

**Resources:**
- `backend-network-policy` - Allows traffic to backend on port 3001
- `frontend-network-policy` - Allows traffic to frontend on port 3000
- `backend-pdb` - Min 1 backend pod available during disruptions
- `frontend-pdb` - Min 1 frontend pod available during disruptions

### 09-rollout-strategies.yaml
ConfigMaps with scripts for canary and blue-green deployment strategies.

**ConfigMaps:**
- `canary-rollout-script` - Progressive traffic shift (10% → 50% → 100%)
- `blue-green-rollout-script` - Instant cutover between versions

## Deployment Architecture

### Blue-Green Deployment
- **Stable (Blue):** 2 replicas serving production traffic
- **Canary (Green):** 1 replica for testing new versions
- Switchover: Direct service selector change

### Canary Deployment
- **Phase 1:** 10% traffic to canary
- **Phase 2:** 50% traffic to canary
- **Phase 3:** 100% traffic to canary
- **Rollback:** Instant revert if issues detected

## Environment Variables

### Backend Configuration
Set in `backend-config` ConfigMap:

```
NODE_ENV=production
PORT=3001
LOG_LEVEL=info
DATABASE_URL=<your-database-url>
```

### Frontend Configuration
Set in `frontend-config` ConfigMap:

```
REACT_APP_API_URL=https://api.wobot.example.com
REACT_APP_ENV=production
```

## Security Features

### Network Security
- Network policies restrict traffic to necessary ports only
- Services use ClusterIP by default (except LoadBalancer)
- Non-root user (UID: 1001) for all containers

### Pod Security
- Read-only root filesystem
- No privileged containers
- No privilege escalation
- Drop all Linux capabilities
- SecurityContext: runAsNonRoot, fsGroup, seccompProfile

### Resource Limits
- **Requests:** 0.5m CPU, 2Mi memory (very low for small nodes)
- **Limits:** 1m CPU, 5Mi memory (strict limits to prevent node overload)

## Scaling and Autoscaling

### Manual Scaling
```bash
# Scale backend stable deployment
kubectl scale deployment backend-stable -n wobot --replicas=3

# Scale frontend stable deployment
kubectl scale deployment frontend-stable -n wobot --replicas=3
```

### Automatic Scaling (HPA)
Configured to scale between 2-5 replicas based on CPU usage:

```bash
# Check HPA status
kubectl get hpa -n wobot

# Check metrics
kubectl top pods -n wobot
kubectl top nodes
```

## Monitoring and Debugging

### View Logs
```bash
# Backend logs
kubectl logs deployment/backend-stable -n wobot
kubectl logs deployment/backend-canary -n wobot

# Frontend logs
kubectl logs deployment/frontend-stable -n wobot
kubectl logs deployment/frontend-canary -n wobot

# Real-time logs
kubectl logs -f deployment/backend-stable -n wobot
```

### Port Forwarding
```bash
# Forward backend port
kubectl port-forward svc/backend-service 3001:3001 -n wobot

# Forward frontend port
kubectl port-forward svc/frontend-service 3000:3000 -n wobot
```

### Get Pod Details
```bash
# Describe a pod
kubectl describe pod <pod-name> -n wobot

# Get pod events
kubectl get events -n wobot

# Check pod resource usage
kubectl top pod <pod-name> -n wobot
```

### Execute Commands in Pod
```bash
# Execute bash in pod
kubectl exec -it <pod-name> -n wobot -- /bin/bash

# Run a single command
kubectl exec <pod-name> -n wobot -- curl http://localhost:3001/health
```

## Health Checks

### Backend Health Check
- **Endpoint:** `GET /health`
- **Port:** 3001
- **Liveness:** 10s initial delay, 10s interval, 5s timeout
- **Readiness:** 5s initial delay, 5s interval, 3s timeout

### Frontend Health Check
- **Endpoint:** `GET /`
- **Port:** 3000
- **Liveness:** 10s initial delay, 10s interval, 5s timeout
- **Readiness:** 5s initial delay, 5s interval, 3s timeout

## Troubleshooting

### Pods not starting
```bash
# Check pod events and logs
kubectl describe pod <pod-name> -n wobot
kubectl logs <pod-name> -n wobot

# Common issues:
# 1. Image pull errors: Check gcr-json-key secret
# 2. Insufficient resources: Check node capacity
# 3. CrashLoopBackOff: Check application logs
```

### Image pull failures
```bash
# Verify secret exists
kubectl get secret gcr-json-key -n wobot

# Check ServiceAccount has imagePullSecrets
kubectl get sa wobot-sa -n wobot -o yaml

# Verify registry credentials
kubectl describe secret gcr-json-key -n wobot
```

### Service not accessible
```bash
# Check service exists
kubectl get svc -n wobot

# Check endpoints
kubectl get endpoints -n wobot

# Check ingress
kubectl get ingress -n wobot -o yaml
```

### Resource limits causing pod restarts
```bash
# Check resource metrics
kubectl top pod -n wobot

# If using >1m CPU or >5Mi memory, pods will be killed
# Increase limits in deployment YAML if needed
```

## Updating Deployments

### Update Image
```bash
# Update backend image
kubectl set image deployment/backend-stable \
  backend=us-central1-docker.pkg.dev/project/backend/wobot-backend:NEW_TAG \
  -n wobot

# Update frontend image
kubectl set image deployment/frontend-stable \
  frontend=us-central1-docker.pkg.dev/project/frontend/wobot-frontend:NEW_TAG \
  -n wobot
```

### Update ConfigMap
```bash
# Edit ConfigMap directly
kubectl edit configmap backend-config -n wobot

# Or apply new ConfigMap YAML
kubectl apply -f 01-configmap.yaml
```

### Restart Deployments
```bash
# Restart backend
kubectl rollout restart deployment/backend-stable -n wobot

# Restart frontend
kubectl rollout restart deployment/frontend-stable -n wobot
```

## Cleanup

### Remove All Resources
```bash
# Delete everything in wobot namespace
kubectl delete namespace wobot

# Or selectively delete resources
kubectl delete deployment --all -n wobot
kubectl delete service --all -n wobot
kubectl delete ingress --all -n wobot
```

## Related Documentation

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## Support

For issues or questions:
1. Check pod logs: `kubectl logs <pod-name> -n wobot`
2. Describe resource: `kubectl describe <resource> <name> -n wobot`
3. Check events: `kubectl get events -n wobot`
4. Review this README and linked documentation
