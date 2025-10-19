variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the instances"
  type        = string
}

variable "zone" {
  description = "The GCP zone for the instances"
  type        = string
}

variable "network" {
  description = "The name of the network"
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnetwork"
  type        = string
}

