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
    prefix = "gke/production"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

################################################################################
# IAM — Service Accounts
################################################################################

module "iam" {
  source = "../../modules/iam"

  project_id     = var.project_id
  project_prefix = var.project_prefix

  workload_service_accounts = {
    "suidex-backend" = {
      display_name  = "Suidex Backend Workload SA"
      k8s_namespace = "default"
      k8s_sa_name   = "suidex-backend"
      roles         = ["roles/secretmanager.secretAccessor"]
    }
    "external-secrets" = {
      display_name  = "External Secrets Operator SA"
      k8s_namespace = "external-secrets"
      k8s_sa_name   = "external-secrets"
      roles = [
        "roles/secretmanager.secretAccessor",
        "roles/iam.serviceAccountTokenCreator",
      ]
    }
  }

  create_cicd_sa = true
  github_repo    = "raut-sanket/gitops-argocd-app-of-apps"
}

################################################################################
# Networking — VPC
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  project_id     = var.project_id
  project_prefix = var.project_prefix
  region         = var.region
  nodes_cidr     = "10.0.0.0/24"
  pods_cidr      = "10.1.0.0/16"
  services_cidr  = "10.2.0.0/20"
}

################################################################################
# GKE Cluster
################################################################################

module "gke" {
  source = "../../modules/gke"

  project_id     = var.project_id
  cluster_prefix = var.project_prefix
  region         = var.region

  network_id          = module.vpc.network_id
  subnet_id           = module.vpc.subnet_id
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  machine_type = "e2-custom-2-8192"
  disk_size_gb = 50
  node_min_count = 1
  node_max_count = 3
  node_zones     = var.node_zones
  preemptible    = false
  spot           = false

  node_service_account_email = module.iam.gke_node_sa_email

  release_channel       = "REGULAR"
  enable_binary_auth    = true
  enable_managed_prometheus = true

  master_authorized_cidrs = var.master_authorized_cidrs

  labels = {
    environment = "production"
    team        = "devops"
    managed-by  = "terraform"
  }
}

################################################################################
# Artifact Registry
################################################################################

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id     = var.project_id
  project_prefix = var.project_prefix
  region         = var.region
  repository_id  = "${var.project_prefix}-docker"

  image_retention_days  = 90
  keep_minimum_versions = 10

  gke_node_sa_email = module.iam.gke_node_sa_email
  cicd_sa_email     = module.iam.cicd_sa_email

  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}
