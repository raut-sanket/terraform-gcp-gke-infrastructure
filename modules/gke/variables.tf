variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_prefix" {
  description = "Prefix for GKE cluster name"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for GKE nodes"
  type        = string
}

variable "pods_range_name" {
  description = "Name of secondary IP range for pods"
  type        = string
}

variable "services_range_name" {
  description = "Name of secondary IP range for services"
  type        = string
}

variable "master_cidr" {
  description = "CIDR block for the GKE master (private cluster)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, STABLE"
  type        = string
  default     = "REGULAR"
}

variable "machine_type" {
  description = "Machine type for node pool"
  type        = string
  default     = "e2-custom-2-8192"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "node_min_count" {
  description = "Minimum nodes per zone in autoscaler"
  type        = number
  default     = 0
}

variable "node_max_count" {
  description = "Maximum nodes per zone in autoscaler"
  type        = number
  default     = 3
}

variable "node_zones" {
  description = "List of zones for node pool"
  type        = list(string)
}

variable "preemptible" {
  description = "Use preemptible VMs for cost savings"
  type        = bool
  default     = false
}

variable "spot" {
  description = "Use spot VMs (newer API, replaces preemptible)"
  type        = bool
  default     = false
}

variable "node_service_account_email" {
  description = "Service account email for GKE nodes"
  type        = string
}

variable "enable_binary_auth" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_managed_prometheus" {
  description = "Enable GKE Managed Prometheus"
  type        = bool
  default     = true
}

variable "master_authorized_cidrs" {
  description = "List of CIDR blocks allowed to access the master"
  type = list(object({
    cidr         = string
    display_name = string
  }))
  default = []
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
