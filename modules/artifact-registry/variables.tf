variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project name prefix"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
}

variable "image_retention_days" {
  description = "Delete images older than this many days"
  type        = number
  default     = 30
}

variable "keep_minimum_versions" {
  description = "Minimum number of image versions to keep"
  type        = number
  default     = 5
}

variable "gke_node_sa_email" {
  description = "GKE node service account email (for reader access)"
  type        = string
  default     = ""
}

variable "cicd_sa_email" {
  description = "CI/CD service account email (for writer access)"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
