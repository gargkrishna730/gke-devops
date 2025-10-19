module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.4"

  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "${var.network_name}-private"
      subnet_ip            = "10.0.0.0/20"
      subnet_region        = var.region
      subnet_private_access = true
      description          = "Private subnet for internal resources"
    },
    {
      subnet_name           = "${var.network_name}-public"
      subnet_ip            = "10.1.0.0/20"
      subnet_region        = var.region
      subnet_private_access = false
      description          = "Public subnet for bastion host"
    }
  ]

  secondary_ranges = {
    "${var.network_name}-private" = [
      {
        range_name    = "gke-pods"
        ip_cidr_range = "10.4.0.0/14"
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = "10.8.0.0/20"
      }
    ]
  }

  routes = [
    {
      name              = "egress-internet"
      description       = "Route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      next_hop_internet = true
      tags              = "egress-inet"
    },
    {
      name              = "public-subnet-internet"
      description       = "Internet route for public subnet"
      destination_range = "0.0.0.0/0"
      next_hop_internet = true
    }
  ]

  firewall_rules = [
    {
      name        = "allow-internal"
      description = "Allow internal traffic"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["10.0.0.0/20", "10.1.0.0/20", "10.4.0.0/14", "10.8.0.0/20"]
      allow = [{
        protocol = "all"
        ports    = []
      }]
    },
    {
      name        = "allow-http"
      description = "Allow HTTP traffic"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["80"]
      }]
    },
    {
      name        = "allow-https"
      description = "Allow HTTPS traffic"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["443"]
      }]
    },
    {
      name        = "allow-health-check"
      description = "Allow health checks"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["130.211.0.0/22", "35.191.0.0/16"]
      target_tags = ["gke-node"]
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443", "8080"]
      }]
    }
  ]
}

# Cloud Router for NAT
resource "google_compute_router" "nat_router" {
  name    = "${var.network_name}-router"
  network = module.vpc.network_id
  region  = var.region
  project = var.project_id

  bgp {
    asn = 64514
  }
}

# Cloud NAT
resource "google_compute_router_nat" "nat_config" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = module.vpc.subnets["${var.region}/${var.network_name}-private"].name
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}