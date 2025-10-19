/**
 * Main Terraform Configuration
 * This file orchestrates all infrastructure modules
 */

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required GCP APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "servicenetworking.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name

  depends_on = [google_project_service.required_apis]
}

# # IAM Module
# module "iam" {
#   source = "./modules/iam"

#   project_id = var.project_id
#   region     = var.region
  
#   depends_on = [google_project_service.required_apis]
# }

# Artifact Registry Module
module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id      = var.project_id
  region          = var.region
  repository_id   = var.artifact_registry_name
  description     = "Docker repository for microservices"
  
  depends_on = [google_project_service.required_apis]
}

# GKE Module
module "gke" {
  source = "./modules/gke"

  project_id           = var.project_id
  region               = var.region
  cluster_name         = "prod-gke-cluster"
  network              = module.vpc.network_name
  subnetwork           = module.vpc.private_subnet_name
  pods_ip_range_name   = "gke-pods"
  services_ip_range_name = "gke-services"
  bastion_subnet_cidr  = "10.1.0.0/20"
  
  initial_node_count   = 1
  min_node_count       = 1
  max_node_count       = 1
  machine_type         = "e2-medium"
  disk_size_gb         = 100
  
  depends_on = [
    module.vpc,
    google_project_service.required_apis
  ]
}
