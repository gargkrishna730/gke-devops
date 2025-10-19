# Terraform Infrastructure Architecture

## Overview

This Terraform configuration provisions a production-ready Google Kubernetes Engine (GKE) infrastructure with supporting services for microservice deployment on Google Cloud Platform (GCP).

**Project ID:** `elegant-atom-475415-c4`  
**Region:** `us-central1`  
**Environment:** Production  

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GCP Project                                  │
│                 (elegant-atom-475415-c4)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
    ┌───▼───┐           ┌────▼─────┐        ┌─────▼──┐
    │  VPC  │           │  GKE     │        │  AR    │
    │       │           │ Cluster  │        │Registry│
    └─┬─────┘           └────┬─────┘        └───────┘
      │                      │
      ├─────────────────┼────┴────┐
      │                 │         │
  ┌───▼────┐      ┌────▼───┐ ┌──▼────┐
  │Private │      │Public  │ │Cloud  │
  │Subnet  │      │Subnet  │ │ NAT   │
  │10.0.0/ │      │10.1.0/ │ │       │
  │20      │      │20      │ │       │
  └─┬──┬───┘      └────────┘ └───────┘
    │  │
    │  └─ GKE Nodes (2-node pool)
    │  └─ Secondary ranges:
    │     - Pods: 10.4.0.0/14
    │     - Services: 10.8.0.0/20
    │
    └─ Cloud Router/NAT
       └─ Egress for private subnet
```

---

## Infrastructure Components

### 1. **VPC (Virtual Private Cloud)**

**Module:** `modules/vpc`  
**Source:** `terraform-google-modules/network/google ~7.4`

#### Network Configuration:
- **Network Name:** `prod-network`
- **Routing Mode:** GLOBAL (inter-region routing)

#### Subnets:

| Subnet | CIDR | Type | Purpose |
|--------|------|------|---------|
| `prod-network-private` | `10.0.0.0/20` | Private | GKE nodes, workloads |
| `prod-network-public` | `10.1.0.0/20` | Public | Reserved for future use |

#### Secondary IP Ranges (for GKE):

| Range Name | CIDR | Purpose |
|------------|------|---------|
| `gke-pods` | `10.4.0.0/14` | Pod IP allocation (Kubernetes) |
| `gke-services` | `10.8.0.0/20` | Service ClusterIP allocation |

#### Cloud NAT & Router:
- **Router Name:** `prod-network-router` (ASN: 64514)
- **NAT Name:** `prod-network-nat`
- **Type:** AUTO_ONLY (automatic external IP allocation)
- **Egress:** Private subnet only
- **Logging:** ERRORS_ONLY

#### Firewall Rules:

| Rule | Direction | Source/Dest | Protocol | Ports | Target | Purpose |
|------|-----------|-------------|----------|-------|--------|---------|
| `allow-internal` | INGRESS | 10.0.0.0/20, 10.1.0.0/20, 10.4.0.0/14, 10.8.0.0/20 | ALL | - | All | Internal traffic |
| `allow-http` | INGRESS | 0.0.0.0/0 | TCP | 80 | All | HTTP access |
| `allow-https` | INGRESS | 0.0.0.0/0 | TCP | 443 | All | HTTPS access |
| `allow-health-check` | INGRESS | 130.211.0.0/22, 35.191.0.0/16 | TCP | 80, 443, 8080 | gke-node | GCP health checks |

---

### 2. **GKE Cluster**

**Module:** `modules/gke`  
**Source:** `terraform-google-modules/kubernetes-engine/google ~30.0`

#### Cluster Configuration:
- **Cluster Name:** `prod-gke-cluster`
- **Location:** `us-central1` (regional cluster)
- **Network:** `prod-network`
- **Subnet:** `prod-network-private`
- **Release Channel:** REGULAR (default)
- **Network Policy:** Enabled

#### Node Pool Configuration:

| Property | Value | Notes |
|----------|-------|-------|
| **Node Pool Name** | `pool-1` | Default node pool |
| **Machine Type** | `e2-medium` | 2 vCPU, 4 GB RAM |
| **Current Nodes** | 2 | Scaled from initial 1 |
| **Min Nodes** | 1 | Minimum for cost optimization |
| **Max Nodes** | 3 | Auto-scaling ceiling |
| **Disk Type** | `pd-balanced` | SSD-backed persistent disk |
| **Disk Size** | 100 GB | Per node |
| **Preemptible** | No | Production stability required |

#### Kubernetes Configuration:
- **IP Allocation Policy:** Enabled
- **Pod IP Range:** 10.4.0.0/14 (gke-pods)
- **Service IP Range:** 10.8.0.0/20 (gke-services)
- **Network Policy:** Enabled (restrict traffic between pods)

#### Access Control:
- **Public Endpoint:** Enabled at `172.16.0.2`
- **Private Endpoint:** Disabled
- **Authorized Networks:** `157.119.202.78/32` (user's public IP)

#### Service Accounts:

**GKE Node Service Account:** `gke-nodes-sa@elegant-atom-475415-c4.iam.gserviceaccount.com`

IAM Roles:
- `roles/logging.logWriter` - Write container logs
- `roles/monitoring.metricWriter` - Write metrics
- `roles/monitoring.viewer` - Read metrics
- `roles/stackdriver.resourceMetadata.writer` - Metadata
- `roles/artifactregistry.reader` - Pull container images from Artifact Registry

#### Data Source:
- The GKE cluster is managed as a **read-only data source** in Terraform
- This prevents accidental cluster recreation
- Node scaling is performed via `gcloud` CLI commands

---

### 3. **Artifact Registry**

**Module:** `modules/artifact-registry`  
**Source:** `GoogleCloudPlatform/artifact-registry/google ~0.5.0`

#### Repositories:

| Repository | Format | Cleanup Policy | Use Case |
|------------|--------|-----------------|----------|
| `frontend` | DOCKER | Delete untagged after 30 days | Frontend microservice images |
| `backend` | DOCKER | Delete untagged after 30 days | Backend microservice images |

#### Service Account for CI/CD:

**Name:** `artifact-registry-push@elegant-atom-475415-c4.iam.gserviceaccount.com`

**IAM Roles:**
- `roles/artifactregistry.writer` - Push Docker images
- `roles/artifactregistry.reader` - Pull Docker images

**Key File:** `/tmp/artifact-registry-push-key.json`

---

### 4. **GCP Project Services**

Enabled APIs:
- `compute.googleapis.com` - Compute Engine
- `container.googleapis.com` - Kubernetes Engine
- `artifactregistry.googleapis.com` - Artifact Registry
- `cloudresourcemanager.googleapis.com` - Resource Manager
- `iam.googleapis.com` - Identity & Access Management
- `servicenetworking.googleapis.com` - Service Networking

---

## Network Flows

### Inbound Traffic:
```
Internet (0.0.0.0/0)
    ↓
GCP Load Balancer (if configured)
    ↓
Firewall: allow-http/allow-https
    ↓
GKE Public Endpoint (172.16.0.2)
    ↓
Kubernetes Services (10.8.0.0/20)
    ↓
Pod IP Range (10.4.0.0/14)
```

### Outbound Traffic (Private Subnet):
```
GKE Nodes (10.0.0.0/20)
    ↓
Cloud NAT (prod-network-nat)
    ↓
GCP External IPs
    ↓
Internet (0.0.0.0/0)
```

### Pod-to-Pod Communication:
```
Pod A (10.4.x.x) ↔ Pod B (10.4.x.x)
    ↓
Kubernetes DNS (10.8.0.0/20)
    ↓
Network Policy (if enforced)
    ↓
Direct routing via 10.0.0.0/20
```

---

## Terraform State Management

**Backend:** Google Cloud Storage (GCS)  
**Bucket:** `wobot-terraform-assignment`  
**State File Path:** `gs://wobot-terraform-assignment/terraform/state/default.tfstate`  
**Locking:** Enabled automatically by GCS backend

### State File Contents:
- VPC network and subnets configuration
- GKE cluster reference (data source)
- Artifact Registry repositories
- Service accounts and IAM bindings
- Cloud Router and NAT configuration

---

## Module Dependencies

```
google_project_service (Enable APIs)
    ↓
    ├─→ module.vpc
    │       ↓
    │   - VPC Network
    │   - Subnets
    │   - Routes
    │   - Firewall Rules
    │   - Cloud Router & NAT
    │
    ├─→ module.artifact_registry
    │       ↓
    │   - Frontend Repository
    │   - Backend Repository
    │   - Service Account
    │   - IAM Bindings
    │
    └─→ module.gke (depends on VPC)
            ↓
        - GKE Cluster (data source)
        - Node Service Account
        - IAM Roles
        - Firewall Rules
```

---

## Security Considerations

### Network Security:
1. **Subnet Isolation:** Private subnet for GKE nodes, isolated from public internet
2. **Firewall Rules:** Least privilege - only required ports open
3. **Network Policy:** Enabled in GKE (deny-all by default, allow specific flows)
4. **Cloud NAT:** No direct internet exposure for private subnet resources

### Identity & Access Control:
1. **Service Accounts:** Separate accounts for GKE nodes and Artifact Registry
2. **IAM Roles:** Minimal required permissions (least privilege principle)
3. **RBAC:** Kubernetes RBAC configured (managed separately)

### Data Protection:
1. **Encryption in Transit:** TLS/HTTPS enforced
2. **Persistent Disks:** `pd-balanced` encrypted by default
3. **State Management:** Terraform state stored in GCS (encrypted at rest)

---

## Cost Optimization

### Current Configuration:
- **GKE Nodes:** 2 x `e2-medium` (~$15/month each)
- **Persistent Disks:** 200 GB total pd-balanced (~$10/month)
- **NAT Gateway:** $0.32/day + data egress (~$10/month)
- **Artifact Registry:** $0.10/GB storage
- **Estimated Monthly Cost:** ~$60-80

### Cost Reduction Strategies:
1. **Use Preemptible Nodes:** Save 60-70% but with 24-hour eviction risk
2. **Auto-Scaling:** Reduce max_node_count if workload is variable
3. **Reserved Instances:** Long-term commitment discounts
4. **Cluster Autoscaling:** Scales down unused nodes automatically

---

## Disaster Recovery & Backup

### Current Setup:
- **No persistent workloads:** Cluster can be destroyed and recreated
- **State Backup:** Terraform state stored in GCS with versioning enabled
- **Code Repository:** All code stored in version control

### Recommendations:
1. Enable GCS versioning for state file backups
2. Implement cluster backup strategy (Google Cloud Backup)
3. Regular disaster recovery drills

---

## Scalability Architecture

### Horizontal Scaling:
- **Node Auto-Scaling:** 1-3 node range (configurable)
- **Pod Auto-Scaling:** HPA (Horizontal Pod Autoscaler) configured separately
- **Multi-Region:** Can be extended to multiple regions

### Vertical Scaling:
- **Node Type:** Change machine_type from e2-medium to e2-standard (easy Terraform change)
- **Disk Size:** Increase disk_size_gb (requires node recreation)

---

## Future Enhancements

1. **Ingress Controller:** NGINX/Istio for advanced routing
2. **Service Mesh:** Istio for observability and traffic management
3. **Monitoring:** Prometheus + Grafana or Google Cloud Monitoring
4. **CI/CD Pipeline:** Cloud Build integration with artifact-registry-push
5. **Multi-Region Cluster:** Global load balancing with regional clusters
6. **Database:** Cloud SQL or Cloud Spanner integration
7. **Secrets Management:** Google Secret Manager integration

---

## Troubleshooting Guide

### Common Issues:

| Issue | Cause | Solution |
|-------|-------|----------|
| Pod IP not reachable | Network policy blocking | Check `kubectl get networkpolicies` |
| Node not ready | Resource quota exceeded | Check `kubectl describe node` |
| Image pull errors | Artifact Registry auth | Verify service account credentials |
| NAT egress fails | NAT gateway down | Check `gcloud compute routers describe` |
| Terraform state lock | Previous apply crashed | Manually force-unlock in GCS |

---