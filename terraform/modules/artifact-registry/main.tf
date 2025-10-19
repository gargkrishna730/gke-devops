# Frontend Repository
module "artifact_registry_frontend" {
  source  = "GoogleCloudPlatform/artifact-registry/google"
  version = "~> 0.5.0"

  project_id    = var.project_id
  location      = var.region
  repository_id = "frontend"
  description   = "Docker repository for frontend microservice"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    service     = "frontend"
  }

  cleanup_policies = {
    "delete-old" = {
      action = "DELETE"
      condition = {
        older_than = "2592000s" # 30 days
        tag_state  = "UNTAGGED"
      }
    }
  }
}

# Backend Repository
module "artifact_registry_backend" {
  source  = "GoogleCloudPlatform/artifact-registry/google"
  version = "~> 0.5.0"

  project_id    = var.project_id
  location      = var.region
  repository_id = "backend"
  description   = "Docker repository for backend microservice"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    service     = "backend"
  }

  cleanup_policies = {
    "delete-old" = {
      action = "DELETE"
      condition = {
        older_than = "2592000s" # 30 days
        tag_state  = "UNTAGGED"
      }
    }
  }
}

# Service Account for pushing images to Artifact Registry
resource "google_service_account" "artifact_registry_push" {
  account_id   = "artifact-registry-push"
  display_name = "Service Account for Pushing Images to Artifact Registry"
  project      = var.project_id
  description  = "Service account with permission to push Docker images to all Artifact Registry repositories"
}

# Grant artifact registry writer role to service account
resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.artifact_registry_push.email}"
}

# Grant artifact registry reader role to service account
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.artifact_registry_push.email}"
}