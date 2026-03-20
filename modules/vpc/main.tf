################################################################################
# VPC Network
################################################################################

resource "google_compute_network" "main" {
  name                    = "${var.project_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

################################################################################
# Subnets
################################################################################

resource "google_compute_subnetwork" "gke_nodes" {
  name                     = "${var.project_prefix}-gke-nodes"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.nodes_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

################################################################################
# Cloud Router + NAT (outbound for private nodes)
################################################################################

resource "google_compute_router" "main" {
  name    = "${var.project_prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.project_prefix}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gke_nodes.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

################################################################################
# Firewall Rules
################################################################################

# Allow internal communication within VPC
resource "google_compute_firewall" "internal" {
  name    = "${var.project_prefix}-allow-internal"
  project = var.project_id
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.nodes_cidr,
    var.pods_cidr,
    var.services_cidr,
  ]

  priority = 1000
}

# Allow health checks from GCP load balancers
resource "google_compute_firewall" "health_checks" {
  name    = "${var.project_prefix}-allow-health-checks"
  project = var.project_id
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
  }

  # Google Cloud health check IP ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  target_tags = ["gke-node"]
  priority    = 1000
}

# Deny all other ingress (explicit)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.project_prefix}-deny-all-ingress"
  project = var.project_id
  network = google_compute_network.main.id

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}
