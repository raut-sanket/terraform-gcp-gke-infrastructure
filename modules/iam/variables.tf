variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "workload_service_accounts" {
  description = "Map of workload identity service accounts"
  type = map(object({
    display_name  = string
    k8s_namespace = string
    k8s_sa_name   = string
    roles         = list(string)
  }))
  default = {}
}

variable "create_cicd_sa" {
  description = "Whether to create a CI/CD service account"
  type        = bool
  default     = false
}

variable "cicd_roles" {
  description = "Roles for CI/CD service account"
  type        = list(string)
  default = [
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/storage.objectViewer",
  ]
}

variable "github_repo" {
  description = "GitHub repo for Workload Identity Federation (org/repo format)"
  type        = string
  default     = ""
}
