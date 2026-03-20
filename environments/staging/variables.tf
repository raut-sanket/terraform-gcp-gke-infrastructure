variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = "suidex"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east4"
}

variable "node_zones" {
  description = "GKE node pool zones"
  type        = list(string)
  default     = ["us-east4-a"]
}
