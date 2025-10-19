terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# GKE Cluster Module - EXISTING CLUSTER
# Data source to reference existing cluster
data "google_container_cluster" "prod" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

# Firewall rule to allow bastion host to access GKE control plane and nodes
resource "google_compute_firewall" "allow_bastion_to_gke" {
  name    = "${var.cluster_name}-allow-bastion"
  network = var.network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443", "10250", "10255"]  # HTTPS for API, Kubelet ports
  }

  source_ranges = [var.bastion_subnet_cidr]
  target_tags   = ["gke-node"]
  description   = "Allow bastion host to access GKE cluster nodes"
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes-sa"
  display_name = "Service Account for GKE Nodes"
  project      = var.project_id
}

# Grant necessary roles to GKE node service account
resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
