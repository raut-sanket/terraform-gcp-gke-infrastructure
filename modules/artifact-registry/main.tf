################################################################################
# Artifact Registry — Container Image Repository
################################################################################

resource "google_artifact_registry_repository" "main" {
  location      = var.region
  project       = var.project_id
  repository_id = var.repository_id
  description   = "Docker container images for ${var.project_prefix}"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      older_than = var.image_retention_days != null ? "${var.image_retention_days * 86400}s" : "2592000s"
    }
  }

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.keep_minimum_versions
    }
  }

  labels = var.labels
}

# Grant pull access to GKE node SA
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  count = var.gke_node_sa_email != "" ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.gke_node_sa_email}"
}

# Grant push access to CI/CD SA
resource "google_artifact_registry_repository_iam_member" "cicd_writer" {
  count = var.cicd_sa_email != "" ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.cicd_sa_email}"
}
