variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "nodes_cidr" {
  description = "CIDR range for GKE node subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "Secondary CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR range for services"
  type        = string
  default     = "10.2.0.0/20"
}
