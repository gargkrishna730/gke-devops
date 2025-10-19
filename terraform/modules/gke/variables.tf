variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "prod-gke-cluster"
}

variable "network" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnet to use"
  type        = string
}

variable "pods_ip_range_name" {
  description = "The secondary IP range name for pods"
  type        = string
  default     = "gke-pods"
}

variable "services_ip_range_name" {
  description = "The secondary IP range name for services"
  type        = string
  default     = "gke-services"
}

variable "initial_node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Size of the disk for nodes in GB"
  type        = number
  default     = 50
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the node pool"
  type        = bool
  default     = true
}

variable "bastion_subnet_cidr" {
  description = "CIDR block of the bastion host subnet (public subnet)"
  type        = string
  default     = "10.1.0.0/20"
}

variable "disk_type" {
  description = "Disk type for node pools (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"
}
