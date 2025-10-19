# Root Level Outputs

output "gke_cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke.kubernetes_cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster endpoint (public IP)"
  value       = module.gke.kubernetes_endpoint
  sensitive   = true
}

output "gke_region" {
  description = "GKE Cluster region"
  value       = module.gke.region
}

output "gke_project_id" {
  description = "GCP Project ID"
  value       = module.gke.project_id
}

output "gke_node_service_account" {
  description = "Service account for GKE nodes"
  value       = module.gke.gke_node_service_account
}

output "vpc_network_name" {
  description = "VPC Network name"
  value       = module.vpc.network_name
}

output "vpc_private_subnet" {
  description = "Private subnet name"
  value       = module.vpc.private_subnet_name
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "us-central1-docker.pkg.dev/${var.project_id}/prod-registry"
}

output "kubectl_connection_command" {
  description = "Command to get kubectl credentials"
  value       = "gcloud container clusters get-credentials prod-gke-cluster --region=us-central1"
}

output "authorized_user_ip" {
  description = "Authorized IP for GKE access"
  value       = "157.119.202.78/32"
}
