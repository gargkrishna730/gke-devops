terraform {
  backend "gcs" {
    bucket = "wobot-terraform-assignment"
    prefix = "terraform/state"
  }
}