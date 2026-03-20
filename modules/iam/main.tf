################################################################################
# GKE Node Service Account (least-privilege)
################################################################################

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.project_prefix}-gke-nodes"
  display_name = "GKE Node Service Account"
  project      = var.project_id
}

# Minimal roles for GKE nodes
locals {
  node_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ]
}

resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset(local.node_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

################################################################################
# Workload Identity — Application SA
################################################################################

resource "google_service_account" "workload" {
  for_each = var.workload_service_accounts

  account_id   = each.key
  display_name = each.value.display_name
  project      = var.project_id
}

# Bind Kubernetes SA ↔ GCP SA via Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = var.workload_service_accounts

  service_account_id = google_service_account.workload[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.k8s_namespace}/${each.value.k8s_sa_name}]"
}

# Grant roles to workload SAs
resource "google_project_iam_member" "workload_roles" {
  for_each = {
    for pair in flatten([
      for sa_key, sa in var.workload_service_accounts : [
        for role in sa.roles : {
          key  = "${sa_key}-${role}"
          sa   = sa_key
          role = role
        }
      ]
    ]) : pair.key => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload[each.value.sa].email}"
}

################################################################################
# CI/CD Service Account (GitHub Actions OIDC)
################################################################################

resource "google_service_account" "cicd" {
  count = var.create_cicd_sa ? 1 : 0

  account_id   = "${var.project_prefix}-cicd"
  display_name = "CI/CD Pipeline Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "cicd_roles" {
  for_each = var.create_cicd_sa ? toset(var.cicd_roles) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cicd[0].email}"
}

# Workload Identity Federation for GitHub Actions OIDC
resource "google_iam_workload_identity_pool" "github" {
  count = var.create_cicd_sa && var.github_repo != "" ? 1 : 0

  workload_identity_pool_id = "${var.project_prefix}-github-pool"
  display_name              = "GitHub Actions Pool"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count = var.create_cicd_sa && var.github_repo != "" ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_actions" {
  count = var.create_cicd_sa && var.github_repo != "" ? 1 : 0

  service_account_id = google_service_account.cicd[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_repo}"
}
