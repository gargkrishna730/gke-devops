output "frontend_repository_id" {
  description = "The ID of the frontend repository"
  value       = "frontend"
}

output "backend_repository_id" {
  description = "The ID of the backend repository"
  value       = "backend"
}

output "frontend_repository_url" {
  description = "Full URL for frontend repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/frontend"
}

output "backend_repository_url" {
  description = "Full URL for backend repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/backend"
}

output "registry_region" {
  description = "Region where repositories are created"
  value       = var.region
}

output "artifact_registry_push_sa_email" {
  description = "Email of service account for pushing images to registry"
  value       = google_service_account.artifact_registry_push.email
}

output "artifact_registry_push_sa_name" {
  description = "Name of service account for pushing images to registry"
  value       = google_service_account.artifact_registry_push.account_id
}
