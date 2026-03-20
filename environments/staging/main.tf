terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "suidex-terraform-state"
    prefix = "gke/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

################################################################################
# IAM
################################################################################

module "iam" {
  source = "../../modules/iam"

  project_id     = var.project_id
  project_prefix = "${var.project_prefix}-staging"

  create_cicd_sa = false
}

################################################################################
# Networking
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  project_id     = var.project_id
  project_prefix = "${var.project_prefix}-staging"
  region         = var.region
  nodes_cidr     = "10.10.0.0/24"
  pods_cidr      = "10.11.0.0/16"
  services_cidr  = "10.12.0.0/20"
}

################################################################################
# GKE Cluster (cost-optimized for staging)
################################################################################

module "gke" {
  source = "../../modules/gke"

  project_id     = var.project_id
  cluster_prefix = "${var.project_prefix}-staging"
  region         = var.region

  network_id          = module.vpc.network_id
  subnet_id           = module.vpc.subnet_id
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  machine_type   = "e2-medium"
  disk_size_gb   = 30
  node_min_count = 0
  node_max_count = 2
  node_zones     = var.node_zones
  preemptible    = false
  spot           = true # Spot VMs for staging — 60-91% cheaper

  node_service_account_email = module.iam.gke_node_sa_email

  release_channel           = "RAPID"
  enable_binary_auth        = false
  enable_managed_prometheus = false

  labels = {
    environment = "staging"
    team        = "devops"
    managed-by  = "terraform"
  }
}

################################################################################
# Artifact Registry (shared — reference output from prod or separate)
################################################################################

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id     = var.project_id
  project_prefix = "${var.project_prefix}-staging"
  region         = var.region
  repository_id  = "${var.project_prefix}-staging-docker"

  image_retention_days  = 14
  keep_minimum_versions = 3

  gke_node_sa_email = module.iam.gke_node_sa_email

  labels = {
    environment = "staging"
    managed-by  = "terraform"
  }
}
