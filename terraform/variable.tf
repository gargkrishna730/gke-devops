/**
 * Variable Definitions
 */

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-vpc"
}



variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "prod-gke-cluster"
}

variable "node_pools" {
  description = "Configuration for GKE node pools"
  type = list(object({
    name               = string
    machine_type       = string
    min_count          = number
    max_count          = number
    initial_node_count = number
    disk_size_gb       = number
    disk_type          = string
    preemptible        = bool
  }))
  default = [
    {
      name               = "pool-1"
      machine_type       = "e2-medium"
      min_count          = 3
      max_count          = 3
      initial_node_count = 3
      disk_size_gb       = 100
      disk_type          = "pd-balanced"
      preemptible        = false
    }
  ]
}

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "microservices-repo"
}

variable "create_bastion" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = true
}

variable "create_utility" {
  description = "Whether to create a utility VM"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "backend" {
  description = "Terraform backend configuration"
  type        = map(string)
  default     = {
    bucket = " wobot-terraform-assignment"
    prefix = "terraform/state"
  } 
}