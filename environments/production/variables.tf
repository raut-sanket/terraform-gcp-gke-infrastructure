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
  default     = ["us-east4-a", "us-east4-b", "us-east4-c"]
}

variable "master_authorized_cidrs" {
  description = "CIDRs allowed to access the K8s API"
  type = list(object({
    cidr         = string
    display_name = string
  }))
  default = []
}
