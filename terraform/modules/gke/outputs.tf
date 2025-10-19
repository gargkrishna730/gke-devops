output "kubernetes_cluster_name" {
  description = "The name of the GKE cluster"
  value       = data.google_container_cluster.prod.name
}

output "kubernetes_cluster_id" {
  description = "The ID of the GKE cluster"
  value       = data.google_container_cluster.prod.id
}

output "region" {
  description = "The region of the GKE cluster"
  value       = data.google_container_cluster.prod.location
}

output "project_id" {
  description = "The project ID"
  value       = var.project_id
}

output "kubernetes_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = data.google_container_cluster.prod.endpoint
  sensitive   = true
}

output "ca_certificate" {
  description = "Cluster ca certificate (base64 encoded)"
  value       = data.google_container_cluster.prod.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_node_service_account" {
  description = "Service account email for GKE nodes"
  value       = google_service_account.gke_nodes.email
}

output "network_policy_enabled" {
  description = "Whether network policy is enabled"
  value       = data.google_container_cluster.prod.network_policy[0].enabled
}
