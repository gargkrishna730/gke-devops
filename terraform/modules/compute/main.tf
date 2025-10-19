/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Create a service account for the instances
resource "google_service_account" "instance_sa" {
  account_id   = "bastion-sa"
  display_name = "Service Account for Bastion Host"
  project      = var.project_id
}

# Grant required roles to the service account
resource "google_project_iam_member" "instance_sa_roles" {
  for_each = toset([
    "roles/compute.viewer",
    "roles/container.viewer",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.instance_sa.email}"
}

# Bastion host template
module "bastion_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 13.0"

  name_prefix          = "bastion"
  project_id          = var.project_id
  machine_type        = "e2-small"
  region              = var.region
  
  service_account = {
    email  = google_service_account.instance_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin
    EOF
  }

  network    = var.network
  subnetwork = var.subnetwork
  tags       = ["bastion", "ssh-allowed"]

  disk_size_gb = 50
  source_image_family = "debian-11"
  source_image_project = "debian-cloud"
}

# Bastion host instance
module "bastion_instance" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "~> 13.0"

  region            = var.region
  zone             = var.zone
  hostname         = "bastion"
  instance_template = module.bastion_template.self_link
  num_instances    = 1

  access_config = [{
    nat_ip       = null
    network_tier = "PREMIUM"
  }]
}

