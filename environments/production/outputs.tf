output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_location" {
  value = module.gke.cluster_location
}

output "registry_url" {
  description = "Docker registry URL"
  value       = module.artifact_registry.repository_url
}

output "gke_node_sa" {
  description = "GKE node service account"
  value       = module.iam.gke_node_sa_email
}

output "get_credentials_command" {
  description = "gcloud command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}
