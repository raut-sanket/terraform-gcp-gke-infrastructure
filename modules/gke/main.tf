################################################################################
# GKE Cluster
################################################################################

resource "google_container_cluster" "primary" {
  name     = "${var.cluster_prefix}-cluster"
  project  = var.project_id
  location = var.region

  # Use separately managed node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnet_id

  # Private cluster — nodes have no public IPs
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Workload Identity — eliminates static SA keys
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy enforcement (Calico)
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    network_policy_config {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Binary Authorization
  binary_authorization {
    evaluation_mode = var.enable_binary_auth ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # Maintenance window — weekday nights
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Release channel for auto-upgrades
  release_channel {
    channel = var.release_channel
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_cidrs) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_cidrs
        content {
          cidr_block   = cidr_blocks.value.cidr
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Security: shielded nodes
  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  resource_labels = var.labels

  lifecycle {
    ignore_changes = [node_config]
  }
}

################################################################################
# Node Pool — General Purpose
################################################################################

resource "google_container_node_pool" "general" {
  name     = "general-purpose"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.primary.name

  # Autoscaling
  autoscaling {
    min_node_count = var.node_min_count
    max_node_count = var.node_max_count
  }

  # Spread across zones
  node_locations = var.node_zones

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-balanced"
    preemptible  = var.preemptible
    spot         = var.spot

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    service_account = var.node_service_account_email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = merge(var.labels, {
      node-pool = "general-purpose"
    })

    tags = ["gke-node", "${var.cluster_prefix}-node"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [
      node_config[0].labels,
    ]
  }
}
